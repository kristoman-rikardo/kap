"""S&P 500 membership reconstruction tests (CP 3.2). Pure, no network."""

from __future__ import annotations

import datetime as dt

from backend.pipeline.sp500 import (
    Company,
    Constituent,
    build_intervals,
    membership_on,
)


def _chg(date, added="", removed=""):
    # Security names populated so build_intervals name-resolution is testable.
    return {
        "date": date,
        "symbol": added,
        "addedSecurity": f"{added} Inc" if added else "",
        "removedTicker": removed,
        "removedSecurity": f"{removed} Inc" if removed else "",
        "reason": "",
    }


def _today(*syms):
    return [{"symbol": s, "name": f"{s} Inc"} for s in syms]


# --- Task 1: membership_on (oracle) -----------------------------------------


def test_membership_on_reverses_changes_after_date():
    today = {"AAA", "BBB"}
    log = [_chg("2020-06-01", added="AAA", removed="CCC")]
    assert membership_on(today, log, dt.date(2019, 1, 1)) == {"CCC", "BBB"}


def test_membership_on_change_exactly_on_date_is_in_effect():
    today = {"AAA", "BBB"}
    log = [_chg("2020-06-01", added="AAA", removed="CCC")]
    assert membership_on(today, log, dt.date(2020, 6, 1)) == {"AAA", "BBB"}


def test_membership_on_pure_addition_only_removes_symbol():
    today = {"AAA", "BBB"}
    log = [_chg("2020-06-01", added="BBB")]
    assert membership_on(today, log, dt.date(2019, 1, 1)) == {"AAA"}


def test_membership_on_ignores_changes_before_or_on_date():
    today = {"AAA"}
    log = [_chg("2010-01-01", added="AAA", removed="ZZZ")]
    assert membership_on(today, log, dt.date(2020, 1, 1)) == {"AAA"}


# --- Task 2: build_intervals ------------------------------------------------


def test_single_membership_open_for_current_member():
    log = [_chg("2010-01-01", added="AAA")]
    build = build_intervals(_today("AAA"), log)
    con = [c for c in build.constituents if c.ticker == "AAA"]
    assert con == [
        Constituent(ticker="AAA", name="AAA Inc", start=dt.date(2010, 1, 1), end=None)
    ]
    assert build.anomalies == []


def test_delisted_ticker_gets_closed_interval_and_flag():
    log = [
        _chg("2010-01-01", added="BBB"),
        _chg("2015-06-01", added="AAA", removed="BBB"),
    ]
    build = build_intervals(_today("AAA"), log)
    bbb_con = [c for c in build.constituents if c.ticker == "BBB"]
    assert bbb_con == [
        Constituent(
            ticker="BBB",
            name="BBB Inc",
            start=dt.date(2010, 1, 1),
            end=dt.date(2015, 6, 1),
        )
    ]
    bbb_co = [c for c in build.companies if c.ticker == "BBB"][0]
    assert bbb_co.is_delisted is True
    assert bbb_co.delisted_date == dt.date(2015, 6, 1)


def test_reentry_produces_two_intervals():
    log = [
        _chg("2010-01-01", added="CCC"),
        _chg("2013-01-01", added="AAA", removed="CCC"),
        _chg("2016-01-01", added="CCC", removed="DDD"),
    ]
    build = build_intervals(_today("CCC", "AAA"), log)
    ccc = sorted(
        [c for c in build.constituents if c.ticker == "CCC"], key=lambda c: c.start
    )
    assert ccc == [
        Constituent("CCC", "CCC Inc", dt.date(2010, 1, 1), dt.date(2013, 1, 1)),
        Constituent("CCC", "CCC Inc", dt.date(2016, 1, 1), None),
    ]


def test_ticker_reuse_flagged_as_anomaly():
    """Same ticker string under two different securities (BBBY-type reuse) →
    two disjoint intervals + a logged anomaly (splitting deferred, 02 §5)."""
    log = [
        {"date": "2010-01-01", "symbol": "XYZ", "addedSecurity": "Old XYZ",
         "removedTicker": "", "removedSecurity": "", "reason": ""},
        {"date": "2014-01-01", "symbol": "AAA", "addedSecurity": "AAA Inc",
         "removedTicker": "XYZ", "removedSecurity": "Old XYZ", "reason": ""},
        {"date": "2018-01-01", "symbol": "XYZ", "addedSecurity": "New XYZ",
         "removedTicker": "DDD", "removedSecurity": "DDD Inc", "reason": ""},
    ]
    build = build_intervals(_today("XYZ", "AAA"), log)
    xyz = sorted(
        [c for c in build.constituents if c.ticker == "XYZ"], key=lambda c: c.start
    )
    assert len(xyz) == 2  # two disjoint intervals
    assert any(
        a.kind == "ticker_reuse" and a.ticker == "XYZ" for a in build.anomalies
    )


def test_no_spurious_anomalies_on_clean_log():
    log = [
        _chg("2010-01-01", added="AAA"),
        _chg("2015-06-01", added="BBB", removed="AAA"),
    ]
    build = build_intervals(_today("BBB"), log)
    assert build.anomalies == []


def test_none_fields_do_not_crash():
    """Real FMP returns null (not '') for removedTicker/removedSecurity on
    ~7 rows. Neither reconstruction may choke on it."""
    log = [
        {
            "date": "2010-01-01",
            "symbol": "AAA",
            "addedSecurity": "AAA Inc",
            "removedTicker": None,
            "removedSecurity": None,
            "reason": "x",
        }
    ]
    assert membership_on({"AAA"}, log, dt.date(2005, 1, 1)) == set()
    build = build_intervals(_today("AAA"), log)
    assert [c.ticker for c in build.constituents] == ["AAA"]


def test_crosscheck_membership_on_matches_intervals():
    log = [
        _chg("2010-01-01", added="BBB"),
        _chg("2015-06-01", added="AAA", removed="BBB"),
    ]
    today = _today("AAA")
    build = build_intervals(today, log)

    def universe_from_intervals(D):
        return {
            c.ticker
            for c in build.constituents
            if c.start <= D and (c.end is None or D < c.end)
        }

    today_syms = {r["symbol"] for r in today}
    for D in [dt.date(2012, 1, 1), dt.date(2016, 1, 1)]:
        assert universe_from_intervals(D) == membership_on(today_syms, log, D)
