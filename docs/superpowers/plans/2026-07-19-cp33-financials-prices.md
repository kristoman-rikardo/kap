# CP 3.3 — Finans + kurser point-in-time: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ingest point-in-time financials (keyed on filing date) and total-return prices so `financials_asof(company_id, decision_date)` returns only what was public then, and `coverage_ok` gates incomplete price series.

**Architecture:** Pure merge/parse functions in `backend/pipeline/financials.py` and `backend/pipeline/prices.py`, each with a `store_*` (idempotent DB write) and a query (`financials_asof` / `coverage_ok`); an orchestrator ingests a small universe. Live checkpoint proves the look-ahead guard against real FMP + DB.

**Tech Stack:** Python (stdlib), psycopg, FMPClient (CP 3.1), pytest.

## Global Constraints

- `uv run pytest backend/tests/ -q` from repo root; deps via `uv add`.
- Verified FMP fields: income/balance have `filingDate`; key-metrics/ratios have only `date`/`period`. `dividend-adjusted` needs from/to; `adjClose` is the TR series.
- filing_date from income-statement (fallback balance-sheet). period_date = income `date`. period_type = 'quarter'.
- pe/ps/cap_category stay NULL — price-dependent, computed by Curator at seal (03 principle 3).
- financials is append-only: `ON CONFLICT (company_id, period_date, period_type, filing_date) DO NOTHING`.
- prices truncated at delisted_date per company_id. coverage_ok excludes gaps > max_gap_days (default 10 trading days); never a silent skip.
- Commit per task; push at end.

---

### Task 1: `merge_period_row` — fuse the four statement sources (pure)

**Files:**
- Create: `backend/pipeline/financials.py`
- Create: `backend/tests/test_financials.py`

**Interfaces:**
- Produces: `merge_period_row(inc: dict, bal: dict | None, km: dict | None, rat: dict | None) -> dict` returning keys: `period_date` (date), `period_type` ("quarter"), `filing_date` (date), `revenue`, `net_income`, `eps`, `debt_to_equity`, `gross_margin`, `operating_margin`, `net_margin`, `roic`, `extra` (dict with `shares_out_dil`, `market_cap_km`). Price-dependent keys (`pe`, `ps`, `cap_category`) are NOT emitted (Curator computes them).

- [ ] **Step 1: Write the failing tests**

```python
import datetime as dt
from backend.pipeline.financials import merge_period_row

def _inc(**kw):
    base = {"date": "2016-03-26", "period": "Q2", "fiscalYear": "2016",
            "filingDate": "2016-04-27", "revenue": 50557000000,
            "netIncome": 10516000000, "epsDiluted": 1.90,
            "weightedAverageShsOutDil": 5500000000}
    base.update(kw); return base

def _rat(**kw):
    base = {"grossProfitMargin": 0.39, "operatingProfitMargin": 0.28,
            "netProfitMargin": 0.208, "debtToEquityRatio": 0.62}
    base.update(kw); return base

def _km(**kw):
    base = {"returnOnInvestedCapital": 0.22, "marketCap": 580000000000}
    base.update(kw); return base

def test_merge_uses_income_filing_date_and_period():
    row = merge_period_row(_inc(), None, _km(), _rat())
    assert row["filing_date"] == dt.date(2016, 4, 27)
    assert row["period_date"] == dt.date(2016, 3, 26)
    assert row["period_type"] == "quarter"

def test_merge_pulls_ratios_and_metrics():
    row = merge_period_row(_inc(), None, _km(), _rat())
    assert row["revenue"] == 50557000000
    assert row["eps"] == 1.90
    assert row["net_margin"] == 0.208
    assert row["debt_to_equity"] == 0.62
    assert row["roic"] == 0.22

def test_merge_omits_price_dependent_fields():
    row = merge_period_row(_inc(), None, _km(), _rat())
    assert "pe" not in row and "ps" not in row and "cap_category" not in row
    assert row["extra"]["shares_out_dil"] == 5500000000

def test_merge_falls_back_to_balance_filing_date():
    inc = _inc(); del inc["filingDate"]
    bal = {"filingDate": "2016-04-28"}
    row = merge_period_row(inc, bal, _km(), _rat())
    assert row["filing_date"] == dt.date(2016, 4, 28)

def test_merge_tolerates_missing_ratios_and_metrics():
    row = merge_period_row(_inc(), None, None, None)
    assert row["roic"] is None and row["net_margin"] is None
    assert row["revenue"] == 50557000000
```

- [ ] **Step 2: Run to verify fail**

Run: `uv run pytest backend/tests/test_financials.py -q`
Expected: import error (module missing).

- [ ] **Step 3: Implement `merge_period_row` in `backend/pipeline/financials.py`**

```python
"""Point-in-time financials ingest (CP 3.3, 03 S3 / 02 §6).

filing_date (the look-ahead anchor) comes only from the statements; ratios
and metrics are joined by (fiscalYear, period). Price-dependent multiples are
deliberately left for the Curator to compute from price(t0) at seal
(03 principle 3), so nothing here fabricates a P/E from a stale price.
"""

from __future__ import annotations

import datetime as dt


def _date(v) -> dt.date | None:
    return dt.date.fromisoformat(v) if v else None


def merge_period_row(
    inc: dict, bal: dict | None, km: dict | None, rat: dict | None
) -> dict:
    bal = bal or {}
    km = km or {}
    rat = rat or {}
    filing = inc.get("filingDate") or bal.get("filingDate")
    return {
        "period_date": _date(inc["date"]),
        "period_type": "quarter",
        "filing_date": _date(filing),
        "revenue": inc.get("revenue"),
        "net_income": inc.get("netIncome"),
        "eps": inc.get("epsDiluted"),
        "debt_to_equity": rat.get("debtToEquityRatio"),
        "gross_margin": rat.get("grossProfitMargin"),
        "operating_margin": rat.get("operatingProfitMargin"),
        "net_margin": rat.get("netProfitMargin"),
        "roic": km.get("returnOnInvestedCapital"),
        "extra": {
            "shares_out_dil": inc.get("weightedAverageShsOutDil"),
            "market_cap_km": km.get("marketCap"),
        },
    }
```

- [ ] **Step 4: Run to verify pass**

Run: `uv run pytest backend/tests/test_financials.py -q`
Expected: 5 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/pipeline/financials.py backend/tests/test_financials.py
git commit -m "CP 3.3 (part 1): merge_period_row — fuse statements point-in-time"
```

---

### Task 2: `fetch_financials` + `store_financials` + `financials_asof`

**Files:**
- Modify: `backend/pipeline/financials.py`
- Modify: `backend/tests/test_financials.py` (add index-join unit test)
- Create: `backend/tests/test_financials_db.py` (env-gated)

**Interfaces:**
- Consumes: `merge_period_row`.
- Produces:
  - `fetch_financials(client, symbol, limit=40) -> list[dict]` (merged rows, newest first).
  - `store_financials(conn, company_id, rows) -> int` (append-only insert count).
  - `financials_asof(conn, company_id, decision_date) -> list[dict]` — one row per period_type, latest period whose `filing_date <= decision_date` (02 §6.2).
  - Helper (pure, testable): `index_by_period(rows) -> dict[tuple[str,str], dict]` keyed on `(str(fiscalYear), period)`.

- [ ] **Step 1: Write the failing unit test for `index_by_period`**

```python
from backend.pipeline.financials import index_by_period

def test_index_by_period_keys_on_fiscalyear_and_period():
    rows = [{"fiscalYear": "2016", "period": "Q2", "x": 1},
            {"fiscalYear": 2015, "period": "Q4", "x": 2}]
    idx = index_by_period(rows)
    assert idx[("2016", "Q2")]["x"] == 1
    assert idx[("2015", "Q4")]["x"] == 2  # int fiscalYear coerced to str
```

- [ ] **Step 2: Run to verify fail**

Run: `uv run pytest backend/tests/test_financials.py::test_index_by_period_keys_on_fiscalyear_and_period -q`
Expected: ImportError.

- [ ] **Step 3: Implement fetch/store/asof + index_by_period**

```python
def index_by_period(rows: list[dict]) -> dict[tuple[str, str], dict]:
    return {(str(r.get("fiscalYear")), r.get("period")): r for r in rows}


def fetch_financials(client, symbol: str, limit: int = 40) -> list[dict]:
    inc = client.get("income-statement", symbol=symbol, period="quarter", limit=limit)
    bal = client.get("balance-sheet-statement", symbol=symbol, period="quarter", limit=limit)
    km = client.get("key-metrics", symbol=symbol, period="quarter", limit=limit)
    rat = client.get("ratios", symbol=symbol, period="quarter", limit=limit)
    bal_i, km_i, rat_i = index_by_period(bal), index_by_period(km), index_by_period(rat)
    out = []
    for r in inc:
        key = (str(r.get("fiscalYear")), r.get("period"))
        merged = merge_period_row(r, bal_i.get(key), km_i.get(key), rat_i.get(key))
        if merged["filing_date"] is None or merged["period_date"] is None:
            continue  # unusable without the point-in-time anchor
        out.append(merged)
    return out


def store_financials(conn, company_id: int, rows: list[dict]) -> int:
    from psycopg.types.json import Jsonb
    n = 0
    with conn.cursor() as cur:
        for r in rows:
            cur.execute(
                """insert into financials
                     (company_id, period_date, period_type, filing_date,
                      revenue, net_income, eps, debt_to_equity,
                      gross_margin, operating_margin, net_margin, roic, extra)
                   values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                   on conflict (company_id, period_date, period_type, filing_date)
                   do nothing""",
                (company_id, r["period_date"], r["period_type"], r["filing_date"],
                 r["revenue"], r["net_income"], r["eps"], r["debt_to_equity"],
                 r["gross_margin"], r["operating_margin"], r["net_margin"],
                 r["roic"], Jsonb(r["extra"])),
            )
            n += cur.rowcount
    conn.commit()
    return n


def financials_asof(conn, company_id: int, decision_date) -> list[dict]:
    """02 §6.2 look-ahead guard: latest period per type known as of the date."""
    rows = conn.execute(
        """with as_of as (
             select distinct on (period_type, period_date) *
             from financials
             where company_id = %s and filing_date <= %s
             order by period_type, period_date desc, filing_date desc)
           select distinct on (period_type) period_type, period_date,
                  filing_date, revenue, eps, roic, net_margin
           from as_of order by period_type, period_date desc""",
        (company_id, decision_date),
    ).fetchall()
    cols = ["period_type","period_date","filing_date","revenue","eps","roic","net_margin"]
    return [dict(zip(cols, r)) for r in rows]
```

- [ ] **Step 4: Run to verify unit test passes**

Run: `uv run pytest backend/tests/test_financials.py -q`
Expected: 6 passed.

- [ ] **Step 5: Write the env-gated DB test** in `backend/tests/test_financials_db.py`

```python
import datetime as dt, os
import pytest
from dotenv import load_dotenv
load_dotenv()
pytestmark = pytest.mark.skipif(not os.environ.get("SUPABASE_DB_URL"),
                                reason="hosted DB not configured")
from backend.pipeline.financials import store_financials, financials_asof

def test_store_and_asof_excludes_future_filings():
    from backend.db import pool
    with pool().connection() as conn:
        cid = conn.execute(
            "insert into companies (ticker, name) values ('ZZTEST','ZZ Test') returning id"
        ).fetchone()[0]
        conn.commit()
        try:
            rows = [
                {"period_date": dt.date(2015,12,31), "period_type":"quarter",
                 "filing_date": dt.date(2016,2,1), "revenue":100, "net_income":10,
                 "eps":1.0, "debt_to_equity":0.5, "gross_margin":0.4,
                 "operating_margin":0.2, "net_margin":0.1, "roic":0.15, "extra":{}},
                # A LATER filing, for a period BEFORE decision_date, must be
                # excluded when we ask as-of 2016-06-02.
                {"period_date": dt.date(2016,3,31), "period_type":"quarter",
                 "filing_date": dt.date(2016,8,1), "revenue":120, "net_income":12,
                 "eps":1.1, "debt_to_equity":0.5, "gross_margin":0.4,
                 "operating_margin":0.2, "net_margin":0.1, "roic":0.16, "extra":{}},
            ]
            assert store_financials(conn, cid, rows) == 2
            asof = financials_asof(conn, cid, dt.date(2016,6,2))
            # Only the Feb-filed row is visible; the Aug-filed one is not.
            assert len(asof) == 1
            assert asof[0]["period_date"] == dt.date(2015,12,31)
        finally:
            conn.execute("delete from financials where company_id=%s", (cid,))
            conn.execute("delete from companies where id=%s", (cid,))
            conn.commit()
```

- [ ] **Step 6: Run the DB test**

Run: `uv run pytest backend/tests/test_financials_db.py -q`
Expected: 1 passed.

- [ ] **Step 7: Commit**

```bash
git add backend/pipeline/financials.py backend/tests/test_financials.py backend/tests/test_financials_db.py
git commit -m "CP 3.3 (part 2): fetch/store financials + financials_asof look-ahead guard"
```

---

### Task 3: Prices — fetch, store (truncate), coverage_ok

**Files:**
- Create: `backend/pipeline/prices.py`
- Create: `backend/tests/test_prices.py`
- Modify: `backend/tests/test_financials_db.py` — no; new `backend/tests/test_prices_db.py` (env-gated)

**Interfaces:**
- Produces:
  - `fetch_prices(client, symbol, start: date, end: date) -> list[dict]` (rows with `date`, `adjClose`).
  - `truncate_at(rows: list[dict], delisted_date: date | None) -> list[dict]` (pure; drop `date > delisted_date`).
  - `store_prices(conn, company_id, rows, delisted_date=None) -> int`.
  - `max_gap_trading_days(dates: list[date]) -> int` (pure; largest run of consecutive weekdays with no row, approximating trading-day gaps).
  - `coverage_ok(conn, company_id, start, end, max_gap_days=10) -> tuple[bool, dict]`.

- [ ] **Step 1: Write the failing pure-function tests**

```python
import datetime as dt
from backend.pipeline.prices import truncate_at, max_gap_trading_days

def test_truncate_drops_rows_after_delisting():
    rows = [{"date":"2016-05-10","adjClose":1},
            {"date":"2016-05-11","adjClose":2},
            {"date":"2016-05-12","adjClose":3}]
    kept = truncate_at(rows, dt.date(2016,5,11))
    assert [r["date"] for r in kept] == ["2016-05-10","2016-05-11"]

def test_truncate_none_keeps_all():
    rows = [{"date":"2016-05-10","adjClose":1}]
    assert truncate_at(rows, None) == rows

def test_max_gap_counts_consecutive_missing_weekdays():
    # Mon 2016-05-02 ... then nothing until Mon 2016-05-09: the week of
    # weekdays in between (Tue-Fri = 4) is the gap.
    dates = [dt.date(2016,5,2), dt.date(2016,5,9)]
    assert max_gap_trading_days(dates) == 4

def test_max_gap_zero_for_consecutive_weekdays():
    dates = [dt.date(2016,5,2), dt.date(2016,5,3), dt.date(2016,5,4)]
    assert max_gap_trading_days(dates) == 0
```

- [ ] **Step 2: Run to verify fail**

Run: `uv run pytest backend/tests/test_prices.py -q`
Expected: ImportError.

- [ ] **Step 3: Implement `backend/pipeline/prices.py`**

```python
"""Total-return price ingest + coverage gate (CP 3.3, 03 S4).

adjClose is the dividend-adjusted total-return series (never use .../full,
which lacks it). Series are truncated at delisted_date per company_id so a
reused ticker (BBBY) never bleeds the next company's prices into the old one.
coverage_ok is the quality gate: a company whose series has a gap longer than
the threshold (or no series at all) is excluded loudly, never silently.
"""

from __future__ import annotations

import datetime as dt


def _date(v) -> dt.date:
    return dt.date.fromisoformat(v)


def fetch_prices(client, symbol: str, start: dt.date, end: dt.date) -> list[dict]:
    rows = client.get(
        "historical-price-eod/dividend-adjusted",
        symbol=symbol, **{"from": start.isoformat(), "to": end.isoformat()},
    )
    return rows if isinstance(rows, list) else []


def truncate_at(rows: list[dict], delisted_date: dt.date | None) -> list[dict]:
    if delisted_date is None:
        return rows
    return [r for r in rows if _date(r["date"]) <= delisted_date]


def store_prices(conn, company_id: int, rows: list[dict],
                 delisted_date: dt.date | None = None) -> int:
    kept = truncate_at(rows, delisted_date)
    n = 0
    with conn.cursor() as cur:
        for r in kept:
            cur.execute(
                """insert into prices (company_id, date, adj_close)
                   values (%s, %s, %s)
                   on conflict (company_id, date) do update
                     set adj_close = excluded.adj_close""",
                (company_id, _date(r["date"]), r["adjClose"]),
            )
            n += 1
    conn.commit()
    return n


def max_gap_trading_days(dates: list[dt.date]) -> int:
    """Largest run of consecutive weekdays (Mon-Fri) with no price row —
    an approximation of trading-day gaps that ignores weekends/holidays."""
    if len(dates) < 2:
        return 0
    ordered = sorted(dates)
    worst = 0
    for a, b in zip(ordered, ordered[1:]):
        gap = 0
        d = a + dt.timedelta(days=1)
        while d < b:
            if d.weekday() < 5:
                gap += 1
            d += dt.timedelta(days=1)
        worst = max(worst, gap)
    return worst


def coverage_ok(conn, company_id: int, start: dt.date, end: dt.date,
                max_gap_days: int = 10) -> tuple[bool, dict]:
    rows = conn.execute(
        "select date from prices where company_id=%s and date between %s and %s "
        "order by date", (company_id, start, end),
    ).fetchall()
    dates = [r[0] for r in rows]
    if not dates:
        return False, {"reason": "no_series", "rows": 0}
    gap = max_gap_trading_days(dates)
    first, last = dates[0], dates[-1]
    lead = max_gap_trading_days([start, first]) if first > start else 0
    tail = max_gap_trading_days([last, end]) if last < end else 0
    ok = gap <= max_gap_days and lead <= max_gap_days and tail <= max_gap_days
    return ok, {"rows": len(dates), "max_gap": gap, "lead_gap": lead,
                "tail_gap": tail, "first": first.isoformat(), "last": last.isoformat()}
```

- [ ] **Step 4: Run to verify pass**

Run: `uv run pytest backend/tests/test_prices.py -q`
Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add backend/pipeline/prices.py backend/tests/test_prices.py
git commit -m "CP 3.3 (part 3): prices — TR fetch, truncate at delisting, coverage_ok"
```

---

### Task 4: Orchestrator + live point-in-time checkpoint + push

**Files:**
- Create: `backend/pipeline/ingest_universe.py`
- Create: `backend/tests/test_cp33_checkpoint.py` (env-gated on FMP + DB)

**Interfaces:**
- Consumes: `fetch_financials`, `store_financials`, `financials_asof`, `fetch_prices`, `store_prices`, `coverage_ok`.
- Produces: `ingest_symbol(client, conn, company_id, symbol, start, end, delisted_date=None) -> dict`; `ingest_universe(client, conn, targets) -> dict` where `targets: list[tuple[company_id, symbol, delisted_date|None]]`, returns `{ingested, price_missing: [...]}`.

- [ ] **Step 1: Write `backend/pipeline/ingest_universe.py`**

```python
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
    ("AAPL", None), ("MSFT", None),
    ("SIVB", dt.date(2023, 3, 10)),   # delisted, has prices -> truncation
    ("SNDK", dt.date(2016, 5, 12)),   # delisted 2016, NO prices -> coverage fails
]


def ingest_symbol(client, conn, company_id, symbol, start, end,
                  delisted_date=None) -> dict:
    fins = fetch_financials(client, symbol)
    n_fin = store_financials(conn, company_id, fins)
    px = fetch_prices(client, symbol, start, end)
    n_px = store_prices(conn, company_id, px, delisted_date)
    ok, detail = coverage_ok(conn, company_id, start,
                             delisted_date or end)
    return {"symbol": symbol, "financials": n_fin, "prices": n_px,
            "coverage_ok": ok, "coverage": detail}


def ingest_universe(client, conn, targets) -> dict:
    start = dt.date(2010, 1, 1)
    end = dt.date.today()
    results, missing = [], []
    for company_id, symbol, delisted in targets:
        r = ingest_symbol(client, conn, company_id, symbol, start,
                          delisted or end, delisted)
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
                    (symbol,)).fetchone()
                if row:
                    targets.append((row[0], symbol, delisted))
            result = ingest_universe(client, conn, targets)
        print("OK:", {"missing": result["price_missing"]})
    finally:
        pool().close()
```

- [ ] **Step 2: Write the live checkpoint test** `backend/tests/test_cp33_checkpoint.py`

```python
"""CP 3.3 checkpoint: point-in-time query returns only filing_date <=
decision_date; coverage_ok passes for a covered name and fails for a delisted
name with no series. Env-gated on FMP + DB."""

import datetime as dt, os
import pytest
from dotenv import load_dotenv
load_dotenv()
pytestmark = pytest.mark.skipif(
    not (os.environ.get("FMP_API_KEY") and os.environ.get("SUPABASE_DB_URL")),
    reason="FMP or DB not configured")

from backend.db import pool
from backend.fmp import FMPClient
from backend.pipeline.financials import fetch_financials, store_financials, financials_asof
from backend.pipeline.prices import coverage_ok, fetch_prices, store_prices

def _cid(conn, ticker, name):
    row = conn.execute("select id from companies where ticker=%s order by id limit 1",
                       (ticker,)).fetchone()
    if row: return row[0]
    cid = conn.execute("insert into companies (ticker, name) values (%s,%s) returning id",
                       (ticker, name)).fetchone()[0]
    conn.commit(); return cid

def test_point_in_time_and_coverage_checkpoint():
    client = FMPClient(key=os.environ["FMP_API_KEY"])
    with pool().connection() as conn:
        aapl = _cid(conn, "AAPL", "Apple Inc.")
        try:
            fins = fetch_financials(client, "AAPL")
            store_financials(conn, aapl, fins)
            D = dt.date(2016, 6, 2)
            asof = financials_asof(conn, aapl, D)
            # Look-ahead guard: every returned row was public by D.
            assert asof, "expected point-in-time rows for AAPL"
            assert all(r["filing_date"] <= D for r in asof)
            # And a period filed AFTER D is not among them.
            latest = max(r["period_date"] for r in asof)
            assert latest < D

            # Coverage: AAPL over 2015-2016 is complete; a never-ingested
            # delisted ticker has no series -> coverage_ok False.
            px = fetch_prices(client, "AAPL", dt.date(2015,1,1), dt.date(2016,12,31))
            store_prices(conn, aapl, px)
            ok, _ = coverage_ok(conn, aapl, dt.date(2015,2,1), dt.date(2016,11,1))
            assert ok is True
            sndk = _cid(conn, "SNDK", "SanDisk Corp")
            no_ok, detail = coverage_ok(conn, sndk, dt.date(2016,1,4), dt.date(2016,6,30))
            assert no_ok is False and detail["reason"] == "no_series"
        finally:
            conn.execute("delete from prices where company_id=%s", (aapl,))
            conn.execute("delete from financials where company_id=%s", (aapl,))
            conn.commit()
```

- [ ] **Step 3: Run the checkpoint**

Run: `uv run pytest backend/tests/test_cp33_checkpoint.py -q`
Expected: 1 passed (the CP 3.3 checkpoint).

- [ ] **Step 4: Run the full backend suite**

Run: `uv run pytest backend/tests/ -q`
Expected: all pass.

- [ ] **Step 5: Commit + push + memory**

```bash
git add backend/pipeline/ingest_universe.py backend/tests/test_cp33_checkpoint.py
git commit -m "CP 3.3 (part 4): orchestrator + live point-in-time checkpoint"
git push origin main
```
Update memory: CP 3.3 done — financials_asof look-ahead guard + coverage_ok; delisted coverage ~76% (TODO_pipeline.md).
