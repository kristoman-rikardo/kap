"""Streak semantics (Wordle-style, 06 §12): consecutive daily days ending
today — or yesterday, so an unplayed today doesn't kill the streak mid-day."""

from __future__ import annotations

import datetime as dt

from backend.stats import compute_streak

TODAY = dt.date(2026, 7, 7)


def d(days_ago: int) -> dt.date:
    return TODAY - dt.timedelta(days=days_ago)


def test_no_days_played():
    assert compute_streak(set(), TODAY) == 0


def test_only_today():
    assert compute_streak({d(0)}, TODAY) == 1


def test_three_day_chain_including_today():
    assert compute_streak({d(0), d(1), d(2)}, TODAY) == 3


def test_gap_resets_to_current_run():
    assert compute_streak({d(0), d(2), d(3)}, TODAY) == 1


def test_chain_ending_yesterday_survives_until_played():
    assert compute_streak({d(1), d(2)}, TODAY) == 2


def test_chain_ending_before_yesterday_is_dead():
    assert compute_streak({d(2), d(3)}, TODAY) == 0
