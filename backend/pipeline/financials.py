"""Point-in-time financials ingest (CP 3.3, 03 S3 / 02 §6).

filing_date (the look-ahead anchor) comes only from the statements; ratios and
metrics are joined by (fiscalYear, period). Price-dependent multiples are
deliberately left for the Curator to compute from price(t0) at seal
(03 principle 3), so nothing here fabricates a P/E from a stale price.

Verified FMP fields (2026-07-19): income/balance carry filingDate; key-metrics
and ratios carry only date/period.
"""

from __future__ import annotations

import datetime as dt

from psycopg.types.json import Jsonb


def _date(v) -> dt.date | None:
    return dt.date.fromisoformat(v) if v else None


def merge_period_row(
    inc: dict, bal: dict | None, km: dict | None, rat: dict | None
) -> dict:
    """Fuse the four statement sources for one (fiscalYear, period) into a
    single price-independent row. pe/ps/cap_category are intentionally absent."""
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


def index_by_period(rows: list[dict]) -> dict[tuple[str, str], dict]:
    """Key rows on (str(fiscalYear), period) for joining across endpoints."""
    return {(str(r.get("fiscalYear")), r.get("period")): r for r in rows}


def fetch_financials(client, symbol: str, limit: int = 40) -> list[dict]:
    """Fetch + merge the four statement endpoints (quarterly). Rows missing
    the point-in-time anchor (filing_date/period_date) are dropped."""
    inc = client.get(
        "income-statement", symbol=symbol, period="quarter", limit=limit
    )
    bal = client.get(
        "balance-sheet-statement", symbol=symbol, period="quarter", limit=limit
    )
    km = client.get("key-metrics", symbol=symbol, period="quarter", limit=limit)
    rat = client.get("ratios", symbol=symbol, period="quarter", limit=limit)
    bal_i, km_i, rat_i = (
        index_by_period(bal),
        index_by_period(km),
        index_by_period(rat),
    )
    out: list[dict] = []
    for r in inc:
        key = (str(r.get("fiscalYear")), r.get("period"))
        merged = merge_period_row(r, bal_i.get(key), km_i.get(key), rat_i.get(key))
        if merged["filing_date"] is None or merged["period_date"] is None:
            continue  # unusable without the point-in-time anchor
        out.append(merged)
    return out


def store_financials(conn, company_id: int, rows: list[dict]) -> int:
    """Append-only upsert (02 §3.2): a refetched filing is a no-op; a
    restatement (new filing_date) would be a new row."""
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
                (
                    company_id, r["period_date"], r["period_type"],
                    r["filing_date"], r["revenue"], r["net_income"], r["eps"],
                    r["debt_to_equity"], r["gross_margin"], r["operating_margin"],
                    r["net_margin"], r["roic"], Jsonb(r["extra"]),
                ),
            )
            n += cur.rowcount
    conn.commit()
    return n


def financials_asof(conn, company_id: int, decision_date) -> list[dict]:
    """02 §6.2 look-ahead guard: latest period per type known as of the date —
    only rows with filing_date <= decision_date, newest period wins."""
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
    cols = [
        "period_type", "period_date", "filing_date",
        "revenue", "eps", "roic", "net_margin",
    ]
    return [dict(zip(cols, r)) for r in rows]
