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


def persist_universe(conn, build: UniverseBuild) -> dict:
    """Upsert companies (natural key (ticker, name) — name disambiguates ticker
    reuse, 02 §5) and rebuild index_constituents, batched into a handful of
    round-trips inside the caller's transaction."""
    with conn.cursor() as cur:
        existing = {
            (t, n): i
            for t, n, i in cur.execute(
                "select ticker, name, id from companies"
            ).fetchall()
        }
        to_update = [
            (c.is_delisted, c.delisted_date, c.ticker, c.name)
            for c in build.companies
            if (c.ticker, c.name) in existing
        ]
        to_insert = [
            (c.ticker, c.name, c.is_delisted, c.delisted_date)
            for c in build.companies
            if (c.ticker, c.name) not in existing
        ]
        if to_update:
            cur.executemany(
                """update companies set is_delisted=%s, delisted_date=%s
                   where ticker=%s and name=%s""",
                to_update,
            )
        if to_insert:
            cur.executemany(
                """insert into companies (ticker, name, is_delisted, delisted_date)
                   values (%s, %s, %s, %s)""",
                to_insert,
            )
        # Reload ids (covers freshly inserted rows) and rebuild constituents.
        ids = {
            (t, n): i
            for t, n, i in cur.execute(
                "select ticker, name, id from companies"
            ).fetchall()
        }
        cur.execute("delete from index_constituents where index_code=%s", (INDEX,))
        cur.executemany(
            """insert into index_constituents (index_code, company_id, membership)
               values (%s, %s, %s)""",
            [
                (INDEX, ids[(c.ticker, c.name)], Range(c.start, c.end, bounds="[)"))
                for c in build.constituents
            ],
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
