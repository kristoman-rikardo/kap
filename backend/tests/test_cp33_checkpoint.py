"""CP 3.3 checkpoint: point-in-time query returns only filing_date <=
decision_date; coverage_ok passes for a covered name and fails for a delisted
name with no series. Env-gated on FMP + DB."""

from __future__ import annotations

import datetime as dt
import os

import pytest
from dotenv import load_dotenv

load_dotenv()

pytestmark = pytest.mark.skipif(
    not (os.environ.get("FMP_API_KEY") and os.environ.get("SUPABASE_DB_URL")),
    reason="FMP or DB not configured",
)

from backend.db import pool
from backend.fmp import FMPClient
from backend.pipeline.financials import (
    fetch_financials,
    financials_asof,
    store_financials,
)
from backend.pipeline.prices import coverage_ok, fetch_prices, store_prices


def _cid(conn, ticker, name):
    row = conn.execute(
        "select id from companies where ticker=%s order by id limit 1", (ticker,)
    ).fetchone()
    if row:
        return row[0]
    cid = conn.execute(
        "insert into companies (ticker, name) values (%s,%s) returning id",
        (ticker, name),
    ).fetchone()[0]
    conn.commit()
    return cid


def test_point_in_time_and_coverage_checkpoint():
    client = FMPClient(key=os.environ["FMP_API_KEY"])
    with pool().connection() as conn:
        aapl = _cid(conn, "AAPL", "Apple Inc.")
        try:
            # limit=60 so the ~15-year window reaches the decision date below;
            # limit=40 only covers back to ~2016 (40 quarters from 2026).
            fins = fetch_financials(client, "AAPL", limit=60)
            store_financials(conn, aapl, fins)
            D = dt.date(2020, 6, 2)
            asof = financials_asof(conn, aapl, D)
            # Look-ahead guard: every returned row was public by D.
            assert asof, "expected point-in-time rows for AAPL"
            assert all(r["filing_date"] <= D for r in asof)
            # The latest visible period ended before the decision date.
            latest = max(r["period_date"] for r in asof)
            assert latest < D
            # Explicit: the very next quarter (filed after D) is NOT visible.
            visible_periods = {r["period_date"] for r in asof}
            future = [
                r for r in fins
                if r["filing_date"] > D and r["period_date"] not in visible_periods
            ]
            assert future, "expected at least one future-filed period to exclude"

            # Coverage: AAPL over 2019-2020 is complete.
            px = fetch_prices(
                client, "AAPL", dt.date(2019, 1, 1), dt.date(2020, 12, 31)
            )
            store_prices(conn, aapl, px)
            ok, _ = coverage_ok(
                conn, aapl, dt.date(2019, 2, 1), dt.date(2020, 11, 1)
            )
            assert ok is True

            # A never-ingested delisted ticker has no series -> excluded.
            sndk = _cid(conn, "SNDK", "SanDisk Corp")
            no_ok, detail = coverage_ok(
                conn, sndk, dt.date(2016, 1, 4), dt.date(2016, 6, 30)
            )
            assert no_ok is False and detail["reason"] == "no_series"
        finally:
            conn.execute("delete from prices where company_id=%s", (aapl,))
            conn.execute("delete from financials where company_id=%s", (aapl,))
            conn.commit()
