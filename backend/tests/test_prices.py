"""Price ingest + coverage-gate tests (CP 3.3). Pure functions, no network."""

from __future__ import annotations

import datetime as dt

from backend.pipeline.prices import max_gap_trading_days, truncate_at


def test_truncate_drops_rows_after_delisting():
    rows = [
        {"date": "2016-05-10", "adjClose": 1},
        {"date": "2016-05-11", "adjClose": 2},
        {"date": "2016-05-12", "adjClose": 3},
    ]
    kept = truncate_at(rows, dt.date(2016, 5, 11))
    assert [r["date"] for r in kept] == ["2016-05-10", "2016-05-11"]


def test_truncate_none_keeps_all():
    rows = [{"date": "2016-05-10", "adjClose": 1}]
    assert truncate_at(rows, None) == rows


def test_max_gap_counts_consecutive_missing_weekdays():
    # Mon 2016-05-02 then nothing until Mon 2016-05-09: the weekdays in
    # between (Tue-Fri = 4) are the gap.
    dates = [dt.date(2016, 5, 2), dt.date(2016, 5, 9)]
    assert max_gap_trading_days(dates) == 4


def test_max_gap_zero_for_consecutive_weekdays():
    dates = [dt.date(2016, 5, 2), dt.date(2016, 5, 3), dt.date(2016, 5, 4)]
    assert max_gap_trading_days(dates) == 0
