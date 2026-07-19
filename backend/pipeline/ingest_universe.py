"""Ingest financials + prices for a set of companies (CP 3.3 orchestrator).

Run:  uv run python -m backend.pipeline.ingest_universe
"""

from __future__ import annotations

import datetime as dt
import logging

from backend.pipeline.financials import fetch_financials, store_financials
from backend.pipeline.prices import coverage_ok, fetch_prices, store_prices

logger = logging.getLogger("kap.ingest")

# Small checkpoint universe: survivors + delisted-with-prices + delisted-without.
CHECKPOINT_TARGETS = [
    ("AAPL", None),
    ("MSFT", None),
    ("SIVB", dt.date(2023, 3, 10)),  # delisted, has prices -> truncation
    ("SNDK", dt.date(2016, 5, 12)),  # delisted 2016, NO prices -> coverage fails
]


def ingest_symbol(
    client, conn, company_id, symbol, start, end, delisted_date=None
) -> dict:
    fins = fetch_financials(client, symbol)
    n_fin = store_financials(conn, company_id, fins)
    px = fetch_prices(client, symbol, start, end)
    n_px = store_prices(conn, company_id, px, delisted_date)
    ok, detail = coverage_ok(conn, company_id, start, delisted_date or end)
    return {
        "symbol": symbol,
        "financials": n_fin,
        "prices": n_px,
        "coverage_ok": ok,
        "coverage": detail,
    }


def ingest_universe(client, conn, targets) -> dict:
    """targets: list[(company_id, symbol, delisted_date|None)]."""
    start = dt.date(2010, 1, 1)
    end = dt.date.today()
    results, missing = [], []
    for company_id, symbol, delisted in targets:
        r = ingest_symbol(
            client, conn, company_id, symbol, start, delisted or end, delisted
        )
        results.append(r)
        if not r["coverage_ok"]:
            missing.append(symbol)
        logger.info("ingested %s: %s", symbol, r)
    return {"ingested": results, "price_missing": missing}


if __name__ == "__main__":
    import os

    from dotenv import load_dotenv

    from backend.db import pool
    from backend.fmp import FMPClient

    load_dotenv()
    logging.basicConfig(level=logging.INFO)
    client = FMPClient(key=os.environ["FMP_API_KEY"])
    try:
        with pool().connection() as conn:
            targets = []
            for symbol, delisted in CHECKPOINT_TARGETS:
                row = conn.execute(
                    "select id from companies where ticker=%s order by id limit 1",
                    (symbol,),
                ).fetchone()
                if row:
                    targets.append((row[0], symbol, delisted))
            result = ingest_universe(client, conn, targets)
        print("OK:", {"missing": result["price_missing"]})
    finally:
        pool().close()
