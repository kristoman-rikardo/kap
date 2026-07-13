"""S&P 500 historical membership reconstruction (CP 3.2, 03 S1).

Two independent computations kept deliberately: membership_on (backward
reconstruction from today's set — the correctness oracle) and build_intervals
(forward replay producing the persisted dateranges). A cross-check test asserts
they agree on historical dates. Pure functions, no I/O.

FMP field shapes (verified 2026-07-13):
- change_log row: date (ISO), symbol+addedSecurity (added), removedTicker+
  removedSecurity (removed, empty on pure add), reason.
- today row: symbol, name, dateFirstAdded.
"""

from __future__ import annotations

import datetime as dt
from dataclasses import dataclass, field


def _parse(d: str) -> dt.date:
    return dt.date.fromisoformat(d)


def _s(value) -> str:
    """Coerce a field to a stripped string. Real FMP returns null (not '')
    for removedTicker/removedSecurity on some rows — None must not crash."""
    return (value or "").strip()


def membership_on(
    today_symbols: set[str], change_log: list[dict], on: dt.date
) -> set[str]:
    """Set of tickers in the index on `on`, by undoing every change after it.

    A change is effective on its `date`, so changes on exactly `on` are kept;
    only changes strictly after `on` are reversed (remove the added symbol,
    restore the removed ticker)."""
    members = set(today_symbols)
    for row in sorted(change_log, key=lambda r: r["date"], reverse=True):
        if _parse(row["date"]) <= on:
            break
        added = _s(row["symbol"])
        removed = _s(row["removedTicker"])
        if added:
            members.discard(added)
        if removed:
            members.add(removed)
    return members


@dataclass(frozen=True)
class Constituent:
    ticker: str
    name: str
    start: dt.date
    end: dt.date | None  # None = [start, infinity) (current member)


@dataclass(frozen=True)
class Company:
    ticker: str
    name: str
    is_delisted: bool
    delisted_date: dt.date | None


@dataclass(frozen=True)
class Anomaly:
    kind: str
    date: str
    ticker: str
    detail: str


@dataclass
class UniverseBuild:
    companies: list[Company] = field(default_factory=list)
    constituents: list[Constituent] = field(default_factory=list)
    anomalies: list[Anomaly] = field(default_factory=list)


def build_intervals(today: list[dict], change_log: list[dict]) -> UniverseBuild:
    """Derive membership intervals from the backward-reconstruction snapshots.

    Anchored on today's known-correct set (never assuming the log is complete):
    membership is a step function that changes only on change dates, so
    snap[d] = membership_on(d) is computed incrementally backward, then a
    forward diff of consecutive snapshots emits each ticker's disjoint
    [start, end) intervals. This is consistent with `membership_on` by
    construction — no fragile event-pairing, so incomplete-log artifacts
    (founding members removed without a matching add) cannot corrupt it.
    """
    today_syms = {r["symbol"] for r in today}
    today_name = {r["symbol"]: (r.get("name") or r["symbol"]) for r in today}

    # Changes grouped by date, carrying the added-security name per add.
    changes_by_date: dict[dt.date, list[tuple[str, str, str]]] = {}
    add_name_at: dict[tuple[str, dt.date], str] = {}
    fallback_name: dict[str, str] = {}
    for row in change_log:
        d = _parse(row["date"])
        added, removed = _s(row["symbol"]), _s(row["removedTicker"])
        added_name, removed_name = _s(row.get("addedSecurity")), _s(
            row.get("removedSecurity")
        )
        changes_by_date.setdefault(d, []).append((added, removed, added_name))
        if added and added_name:
            add_name_at[(added, d)] = added_name
            fallback_name[added] = added_name
        if removed and removed_name:
            fallback_name.setdefault(removed, removed_name)

    def name_of(ticker: str) -> str:
        return today_name.get(ticker) or fallback_name.get(ticker) or ticker

    # snap[d] = membership_on(d), computed by undoing changes backward from
    # today's set (each snapshot is the membership for the segment [d, next)).
    current = set(today_syms)
    snap: dict[dt.date, set[str]] = {}
    for d in sorted(changes_by_date, reverse=True):
        snap[d] = set(current)
        for added, removed, _n in changes_by_date[d]:
            if added:
                current.discard(added)
            if removed:
                current.add(removed)

    # Forward diff of consecutive snapshots -> intervals. Track the security
    # name seen at each entry to flag ticker reuse.
    build = UniverseBuild()
    open_start: dict[str, dt.date] = {}
    entry_names: dict[str, set[str]] = {}
    prev: set[str] = set()
    for d in sorted(changes_by_date):
        members = snap[d]
        for t in members - prev:  # entered the index
            open_start[t] = d
            entry_names.setdefault(t, set()).add(
                add_name_at.get((t, d)) or name_of(t)
            )
        for t in prev - members:  # left the index
            build.constituents.append(Constituent(t, name_of(t), open_start.pop(t), d))
        prev = members
    for t in list(open_start):  # still members -> open interval
        build.constituents.append(Constituent(t, name_of(t), open_start.pop(t), None))

    # Companies: one per ticker. is_delisted = absent from today's list;
    # delisted_date = end of its last interval.
    for ticker in sorted({c.ticker for c in build.constituents}):
        in_today = ticker in today_syms
        ends = [c.end for c in build.constituents if c.ticker == ticker and c.end]
        build.companies.append(
            Company(
                ticker=ticker,
                name=name_of(ticker),
                is_delisted=not in_today,
                delisted_date=None if in_today else (max(ends) if ends else None),
            )
        )
        if len(entry_names.get(ticker, ())) > 1:
            build.anomalies.append(
                Anomaly(
                    "ticker_reuse", "", ticker,
                    f"multiple securities under one ticker: "
                    f"{sorted(entry_names[ticker])}",
                )
            )
    return build


def fetch_sp500(client) -> tuple[list[dict], list[dict]]:
    """(today's constituents, full change log) from FMP (03 S1)."""
    today = client.get("sp500-constituent")
    change_log = client.get("historical-sp500-constituent")
    return today, change_log
