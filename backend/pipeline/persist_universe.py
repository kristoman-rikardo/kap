"""Persist reconstructed S&P 500 membership (CP 3.2, 03 S1 / 02 §4).

FastAPI/pipeline runs as the service role (bypasses RLS). Idempotent: every
run recomputes the whole membership, so index_constituents is rebuilt
(delete-all-SP500 + insert) inside the caller's transaction; companies are
upserted on the natural key (ticker, name).
"""

from __future__ import annotations

import datetime as dt

from psycopg.types.range import Range

from backend.pipeline.sp500 import UniverseBuild

INDEX = "SP500"


def _company_id(
    cur,
    ticker: str,
    name: str,
    is_delisted: bool,
    delisted_date: dt.date | None,
) -> int:
    """Upsert on the natural key (ticker, name); name disambiguates ticker
    reuse across distinct companies (02 §5)."""
    row = cur.execute(
        "select id from companies where ticker=%s and name=%s", (ticker, name)
    ).fetchone()
    if row:
        cur.execute(
            "update companies set is_delisted=%s, delisted_date=%s where id=%s",
            (is_delisted, delisted_date, row[0]),
        )
        return row[0]
    return cur.execute(
        """insert into companies (ticker, name, is_delisted, delisted_date)
           values (%s, %s, %s, %s) returning id""",
        (ticker, name, is_delisted, delisted_date),
    ).fetchone()[0]


def persist_universe(conn, build: UniverseBuild) -> dict:
    """Upsert companies and rebuild index_constituents in one transaction."""
    with conn.cursor() as cur:
        ids: dict[tuple[str, str], int] = {}
        for c in build.companies:
            ids[(c.ticker, c.name)] = _company_id(
                cur, c.ticker, c.name, c.is_delisted, c.delisted_date
            )
        cur.execute(
            "delete from index_constituents where index_code=%s", (INDEX,)
        )
        for con in build.constituents:
            cid = ids[(con.ticker, con.name)]
            # Half-open [start, end); end=None -> [start, infinity).
            rng = Range(con.start, con.end, bounds="[)")
            cur.execute(
                """insert into index_constituents (index_code, company_id, membership)
                   values (%s, %s, %s)""",
                (INDEX, cid, rng),
            )
    conn.commit()
    return {
        "companies": len(build.companies),
        "constituents": len(build.constituents),
        "anomalies": len(build.anomalies),
    }


def universe(conn, on: dt.date) -> set[int]:
    """company_ids in the index on `on` — the survivorship-correct universe."""
    rows = conn.execute(
        """select company_id from index_constituents
           where index_code=%s and membership @> %s""",
        (INDEX, on),
    ).fetchall()
    return {r[0] for r in rows}
