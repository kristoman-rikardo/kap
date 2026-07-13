"""Build + persist S&P 500 historical membership (CP 3.2 orchestrator).

Run:  uv run python -m backend.pipeline.build_universe
"""

from __future__ import annotations

import logging

from backend.db import pool
from backend.pipeline.persist_universe import persist_universe
from backend.pipeline.sp500 import build_intervals, fetch_sp500

logger = logging.getLogger("kap.universe")


def build_and_persist(client, conn) -> dict:
    today, change_log = fetch_sp500(client)
    build = build_intervals(today, change_log)
    counts = persist_universe(conn, build)
    logger.info(
        "universe persisted: %s (%d anomalies logged)",
        counts,
        len(build.anomalies),
    )
    return counts


if __name__ == "__main__":
    import os

    from dotenv import load_dotenv

    from backend.fmp import FMPClient

    load_dotenv()
    logging.basicConfig(level=logging.INFO)
    client = FMPClient(key=os.environ["FMP_API_KEY"])
    try:
        with pool().connection() as conn:
            result = build_and_persist(client, conn)
        print("OK:", result)
    finally:
        pool().close()
