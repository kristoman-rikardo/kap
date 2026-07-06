"""Postgres connection pool (CP 2.3).

FastAPI is the service role (05 §2): it connects as the table owner via the
Supabase session pooler (IPv4; the direct host is IPv6-only) and therefore
bypasses RLS — which is exactly why *all* anonymization/stripping logic lives
in the API layer, never in the client.
"""

from __future__ import annotations

import os
from functools import lru_cache

from dotenv import load_dotenv
from psycopg_pool import ConnectionPool

load_dotenv()


@lru_cache
def pool() -> ConnectionPool:
    url = os.environ.get("SUPABASE_DB_URL")
    if not url:
        raise RuntimeError("SUPABASE_DB_URL mangler (sett den i .env)")
    # Liten pool: dev + hobby-trafikk; session-pooleren har egne tak.
    return ConnectionPool(url, min_size=0, max_size=4, open=True)
