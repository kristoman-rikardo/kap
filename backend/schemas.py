"""Pydantic models for KAP API response contracts (05_api.md, 02 §8).

CP 1.1: only the anonymized daily-batch shape. Field names are snake_case to
match the JSON in 05 §4.1; the Flutter freezed models (06 §4) mirror these.
Nothing here ever carries name / ticker / decision_date — that is the
anonymization boundary (05 §5).
"""

from __future__ import annotations

from pydantic import BaseModel


class Macro(BaseModel):
    """Banded macro context — no numbers, no year (04 §5.7)."""

    rate_level: str  # 'lav' | 'nøytral' | 'høy'
    rate_direction: str  # 'stigende' | 'flat' | 'fallende'
    inflation_band: str
    gdp_band: str
    sector_sentiment: str


class Fundamentals(BaseModel):
    pe: float | None = None  # null when EPS is negative -> shown as "neg." (04 §5.2)
    ps: float
    debt_to_equity: float
    gross_margin: float
    operating_margin: float
    net_margin: float
    roic: float


class Growth(BaseModel):
    rev_cagr_3y: float
    eps_cagr_3y: float


class CardPayload(BaseModel):
    """Exactly what the client sees — anonymized (02 §8). No name/ticker/amounts."""

    macro: Macro
    fundamentals: Fundamentals
    growth: Growth
    cap: str  # 'small' | 'mid' | 'large' (bånd, 04 §5.2)
    sector_coarse: str
    narrative: str


class Card(BaseModel):
    card_no: int
    payload: CardPayload


class Intro(BaseModel):
    """Period framing shown before card 1 (Instructions §3, batch-level)."""

    market_sentiment: str
    rate_picture: str
    note: str


class DailyBatch(BaseModel):
    batch_id: int
    mode: str  # 'junior'
    is_daily: bool
    daily_date: str  # ISO date of the round; decision_date (the era) is never sent
    horizon_years: int
    intro: Intro
    cards: list[Card]
