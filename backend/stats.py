"""User-facing aggregates (05 §4.5). Pure functions — no I/O."""

from __future__ import annotations

import datetime as dt


def compute_streak(played: set[dt.date], today: dt.date) -> int:
    """Consecutive daily days ending today, or yesterday if today is still
    unplayed (the streak isn't dead until the day is actually missed)."""
    day = today if today in played else today - dt.timedelta(days=1)
    if day not in played:
        return 0
    streak = 0
    while day in played:
        streak += 1
        day -= dt.timedelta(days=1)
    return streak
