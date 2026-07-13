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
        added = row["symbol"].strip()
        removed = row["removedTicker"].strip()
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
    """Forward event-replay: per ticker, a state machine over its add/remove
    events yields disjoint [start, end) intervals, reconciled with today's
    list. Inconsistent transitions are recorded as anomalies, never raised."""
    today_syms = {r["symbol"] for r in today}
    today_name = {r["symbol"]: r.get("name", r["symbol"]) for r in today}

    events: dict[str, list[tuple[dt.date, str, str]]] = {}
    for row in change_log:
        d = _parse(row["date"])
        added = row["symbol"].strip()
        removed = row["removedTicker"].strip()
        if added:
            events.setdefault(added, []).append(
                (d, "add", row.get("addedSecurity", "").strip())
            )
        if removed:
            events.setdefault(removed, []).append(
                (d, "remove", row.get("removedSecurity", "").strip())
            )

    build = UniverseBuild()
    for ticker, evs in events.items():
        evs.sort(key=lambda e: e[0])
        # Name: prefer today's list for current members, else the most recent
        # non-empty security name seen in the log.
        name = today_name.get(ticker) or next(
            (n for _, _, n in reversed(evs) if n), ticker
        )
        open_start: dt.date | None = None
        last_remove: dt.date | None = None
        for d, kind, _n in evs:
            if kind == "add":
                if open_start is None:
                    open_start = d
                else:
                    build.anomalies.append(
                        Anomaly(
                            "double_add", d.isoformat(), ticker,
                            "add while already a member",
                        )
                    )
            else:  # remove
                if open_start is not None:
                    build.constituents.append(
                        Constituent(ticker, name, open_start, d)
                    )
                    open_start = None
                    last_remove = d
                else:
                    build.anomalies.append(
                        Anomaly(
                            "remove_without_add", d.isoformat(), ticker,
                            "remove while not a member",
                        )
                    )
        in_today = ticker in today_syms
        if open_start is not None:
            if in_today:
                build.constituents.append(
                    Constituent(ticker, name, open_start, None)
                )
            else:
                build.anomalies.append(
                    Anomaly(
                        "open_but_absent", open_start.isoformat(), ticker,
                        "log leaves ticker current but absent from today's list",
                    )
                )
        elif in_today:
            build.anomalies.append(
                Anomaly(
                    "closed_but_current", "", ticker,
                    "today's list has ticker but log ended removed",
                )
            )
        build.companies.append(
            Company(
                ticker=ticker,
                name=name,
                is_delisted=not in_today,
                delisted_date=None if in_today else last_remove,
            )
        )

    # Current members that never appear in the change log (defensive; none
    # expected from this log). Bound the start with dateFirstAdded.
    for row in today:
        if row["symbol"] not in events:
            sym = row["symbol"]
            build.companies.append(Company(sym, today_name[sym], False, None))
            start = row.get("dateFirstAdded")
            build.constituents.append(
                Constituent(
                    sym,
                    today_name[sym],
                    _parse(start) if start else dt.date(1957, 3, 4),
                    None,
                )
            )
    return build


def fetch_sp500(client) -> tuple[list[dict], list[dict]]:
    """(today's constituents, full change log) from FMP (03 S1)."""
    today = client.get("sp500-constituent")
    change_log = client.get("historical-sp500-constituent")
    return today, change_log
