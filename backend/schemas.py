"""Pydantic models for KAP API response contracts (05_api.md, 02 §8).

CP 1.1: only the anonymized daily-batch shape. Field names are snake_case to
match the JSON in 05 §4.1; the Flutter freezed models (06 §4) mirror these.
Nothing here ever carries name / ticker / decision_date — that is the
anonymization boundary (05 §5).
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel

ChoiceValue = Literal["long", "short", "cash"]


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


# --- Submit / reveal (05 §4.3; the response is the 01 §7 contract) -----------
#
# Everything below only ever travels in the POST submit response — the single
# place truth (name/ticker/alpha/clue) and decision_date are exposed (05 §5).


class ChoiceIn(BaseModel):
    card_no: int
    choice: ChoiceValue
    weight: float | None = None  # Manager-only; null in Junior
    response_ms: int | None = None  # analytics (02 §9)


class SubmitRequest(BaseModel):
    choices: list[ChoiceIn]


class Benchmark(BaseModel):
    """Batch-level truth, frozen per batch so alpha_cash is auditable (01 §6.6)."""

    R_m: float  # cumulative benchmark total return over the horizon
    r_m: float  # annualized
    r_f: float  # annualized risk-free
    alpha_cash: float  # r_f - r_m, same for every card in the batch


class RevealCard(BaseModel):
    """Per-card truth + the user's outcome (01 §7)."""

    card_no: int
    ticker: str
    name: str
    choice: ChoiceValue
    R: float  # cumulative total return
    r: float  # annualized
    alpha: float  # r - r_m
    a: float  # the user's alpha contribution given their choice (01 §3.1)
    points: float  # P(a), the squashed game-layer number
    clue: str
    event: Literal["acquired", "delisted"] | None = None
    company_id: int


class IdealChoice(BaseModel):
    card_no: int
    choice: ChoiceValue


class Ideal(BaseModel):
    """Hindsight portfolio (01 §8): long every alpha>0, short every alpha<0."""

    choices: list[IdealChoice]
    score: float


class Reveal(BaseModel):
    session_id: int
    score: float
    bonus: float
    hit_rate: float | None  # null when the round had no long/short choices
    benchmark: Benchmark
    decision_date: str  # the era — only revealed after submit (05 §5)
    horizon_years: int
    cards: list[RevealCard]
    ideal: Ideal
