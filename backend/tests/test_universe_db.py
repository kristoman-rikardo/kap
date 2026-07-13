"""Universe persistence + query against the hosted DB (CP 3.2). Env-gated."""

from __future__ import annotations

import datetime as dt
import os

import pytest
from dotenv import load_dotenv

load_dotenv()

pytestmark = pytest.mark.skipif(
    not os.environ.get("SUPABASE_DB_URL"), reason="hosted DB not configured"
)

from backend.pipeline.persist_universe import persist_universe, universe
from backend.pipeline.sp500 import build_intervals


def _chg(date, added="", removed=""):
    return {
        "date": date,
        "symbol": added,
        "addedSecurity": f"{added} Inc" if added else "",
        "removedTicker": removed,
        "removedSecurity": f"{removed} Inc" if removed else "",
        "reason": "",
    }


def test_persist_and_query_roundtrip():
    from backend.db import pool

    today = [{"symbol": "AAA", "name": "AAA Inc"}]
    log = [
        _chg("2010-01-01", added="BBB"),
        _chg("2015-06-01", added="AAA", removed="BBB"),
    ]
    build = build_intervals(today, log)
    with pool().connection() as conn:
        try:
            counts = persist_universe(conn, build)
            assert counts["constituents"] == 2
            u2012 = universe(conn, dt.date(2012, 1, 1))
            u2016 = universe(conn, dt.date(2016, 1, 1))
            ids = dict(
                conn.execute(
                    "select ticker, id from companies where ticker in ('AAA','BBB')"
                ).fetchall()
            )
            assert ids["BBB"] in u2012 and ids["AAA"] not in u2012
            assert ids["AAA"] in u2016 and ids["BBB"] not in u2016
        finally:
            conn.execute(
                "delete from index_constituents where index_code='SP500'"
            )
            conn.execute("delete from companies where ticker in ('AAA','BBB')")
            conn.commit()
