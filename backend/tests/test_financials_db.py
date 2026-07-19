"""financials store + look-ahead guard against the hosted DB (CP 3.3).
Env-gated."""

from __future__ import annotations

import datetime as dt
import os

import pytest
from dotenv import load_dotenv

load_dotenv()

pytestmark = pytest.mark.skipif(
    not os.environ.get("SUPABASE_DB_URL"), reason="hosted DB not configured"
)

from backend.pipeline.financials import financials_asof, store_financials


def test_store_and_asof_excludes_future_filings():
    from backend.db import pool

    with pool().connection() as conn:
        cid = conn.execute(
            "insert into companies (ticker, name) values ('ZZTEST','ZZ Test') "
            "returning id"
        ).fetchone()[0]
        conn.commit()
        try:
            rows = [
                {
                    "period_date": dt.date(2015, 12, 31), "period_type": "quarter",
                    "filing_date": dt.date(2016, 2, 1), "revenue": 100,
                    "net_income": 10, "eps": 1.0, "debt_to_equity": 0.5,
                    "gross_margin": 0.4, "operating_margin": 0.2,
                    "net_margin": 0.1, "roic": 0.15, "extra": {},
                },
                # A LATER filing, for a period before decision_date, must be
                # excluded when we ask as-of 2016-06-02.
                {
                    "period_date": dt.date(2016, 3, 31), "period_type": "quarter",
                    "filing_date": dt.date(2016, 8, 1), "revenue": 120,
                    "net_income": 12, "eps": 1.1, "debt_to_equity": 0.5,
                    "gross_margin": 0.4, "operating_margin": 0.2,
                    "net_margin": 0.1, "roic": 0.16, "extra": {},
                },
            ]
            assert store_financials(conn, cid, rows) == 2
            asof = financials_asof(conn, cid, dt.date(2016, 6, 2))
            # Only the Feb-filed row is visible; the Aug-filed one is not.
            assert len(asof) == 1
            assert asof[0]["period_date"] == dt.date(2015, 12, 31)
        finally:
            conn.execute("delete from financials where company_id=%s", (cid,))
            conn.execute("delete from companies where id=%s", (cid,))
            conn.commit()
