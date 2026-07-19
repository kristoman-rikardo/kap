"""Total-return price ingest + coverage gate (CP 3.3, 03 S4).

adjClose is the dividend-adjusted total-return series (never use .../full,
which lacks it). Series are truncated at delisted_date per company_id so a
reused ticker (BBBY) never bleeds the next company's prices into the old one.
coverage_ok is the quality gate: a company whose series has a gap longer than
the threshold (or no series at all) is excluded loudly, never silently
(03 principle 5).
"""

from __future__ import annotations

import datetime as dt


def _date(v) -> dt.date:
    return dt.date.fromisoformat(v)


def fetch_prices(client, symbol: str, start: dt.date, end: dt.date) -> list[dict]:
    """dividend-adjusted EOD (requires from/to). Empty list if no coverage."""
    rows = client.get(
        "historical-price-eod/dividend-adjusted",
        symbol=symbol,
        **{"from": start.isoformat(), "to": end.isoformat()},
    )
    return rows if isinstance(rows, list) else []


def truncate_at(rows: list[dict], delisted_date: dt.date | None) -> list[dict]:
    """Drop rows dated after delisting (per company_id, ticker-reuse safety)."""
    if delisted_date is None:
        return rows
    return [r for r in rows if _date(r["date"]) <= delisted_date]


def store_prices(
    conn,
    company_id: int,
    rows: list[dict],
    delisted_date: dt.date | None = None,
) -> int:
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
    """Largest run of consecutive weekdays (Mon-Fri) with no price row — an
    approximation of trading-day gaps that ignores weekends and holidays."""
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


def coverage_ok(
    conn,
    company_id: int,
    start: dt.date,
    end: dt.date,
    max_gap_days: int = 10,
) -> tuple[bool, dict]:
    """Does the stored series cover [start, end] without an internal, leading,
    or trailing weekday-gap longer than the threshold? No series -> False."""
    rows = conn.execute(
        "select date from prices where company_id=%s and date between %s and %s "
        "order by date",
        (company_id, start, end),
    ).fetchall()
    dates = [r[0] for r in rows]
    if not dates:
        return False, {"reason": "no_series", "rows": 0}
    gap = max_gap_trading_days(dates)
    first, last = dates[0], dates[-1]
    lead = max_gap_trading_days([start, first]) if first > start else 0
    tail = max_gap_trading_days([last, end]) if last < end else 0
    ok = gap <= max_gap_days and lead <= max_gap_days and tail <= max_gap_days
    return ok, {
        "rows": len(dates),
        "max_gap": gap,
        "lead_gap": lead,
        "tail_gap": tail,
        "first": first.isoformat(),
        "last": last.isoformat(),
    }
