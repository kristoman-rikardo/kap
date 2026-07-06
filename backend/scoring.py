"""The KAP scoring engine — 01_scoring.md as a pure function (CP 1.3).

Junior Mode only for now (01 §3); Manager's portfolio scoring (01 §4) comes
with its own phase. Everything here is deterministic and side-effect free:
truth in, scores out. The engine validates its inputs and never guesses
(01 §6.3) — bad input is a ValueError, not a silently wrong score.

Notation follows 01 §2: capital R = cumulative total return over the horizon,
lower r = annualized, alpha = r - r_m.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

VALID_CHOICES = ("long", "short", "cash")


@dataclass(frozen=True)
class ScoringConfig:
    """01 §9 parameter table. tau is the annualized alpha scale where points
    start saturating; perfect_bonus rewards a_i > 0 on every card."""

    tau: float = 0.15
    perfect_bonus: float = 25.0


DEFAULT_CONFIG = ScoringConfig()


@dataclass(frozen=True)
class CardTruth:
    card_no: int
    R: float  # cumulative total return over [t0, t1]; -1.0 = wiped out


@dataclass(frozen=True)
class BenchmarkTruth:
    R_m: float  # cumulative benchmark total return
    R_f: float  # cumulative risk-free return
    horizon_years: float


@dataclass(frozen=True)
class CardScore:
    card_no: int
    choice: str
    R: float
    r: float
    alpha: float
    a: float  # the user's alpha contribution given their choice (01 §3.1)
    points: float  # P(a) = 100·tanh(a/tau)


@dataclass(frozen=True)
class JuniorScore:
    score: float  # Σ points + bonus (01 §3.1)
    bonus: float
    hit_rate: float | None  # None when the round had no long/short choices
    r_m: float
    r_f: float
    alpha_cash: float
    cards: tuple[CardScore, ...]


def annualize(R: float, horizon_years: float) -> float:
    """(1+R)^(1/H) - 1. Well-defined down to R = -1 (total loss -> -100 %/yr)."""
    if R < -1.0:
        raise ValueError(f"Kumulativ avkastning kan ikke være under -100 %: {R}")
    return (1.0 + R) ** (1.0 / horizon_years) - 1.0


def squash(x: float, tau: float = DEFAULT_CONFIG.tau) -> float:
    """The shared point mapping P(x) = 100·tanh(x/tau) (01 §2): monotone,
    ~linear near zero (1 %-point alpha ≈ 6.7 points), bounded to ±100 so one
    extreme card can never dominate more than one perfect card."""
    return 100.0 * math.tanh(x / tau)


def alpha_contribution(choice: str, alpha: float, alpha_cash: float) -> float:
    """a_i per 01 §3.1: long -> alpha, short -> -alpha, cash -> alpha_cash."""
    if choice == "long":
        return alpha
    if choice == "short":
        return -alpha
    if choice == "cash":
        return alpha_cash
    raise ValueError(f"Ugyldig valg: {choice!r} (må være long/short/cash)")


def score_junior(
    cards: list[CardTruth],
    choices: dict[int, str],
    benchmark: BenchmarkTruth,
    config: ScoringConfig = DEFAULT_CONFIG,
) -> JuniorScore:
    """Score one Junior round (01 §3).

    `choices` maps card_no -> 'long'|'short'|'cash' and must cover the cards
    exactly. The result is invariant to card order (01 §10.5).
    """
    if benchmark.horizon_years <= 0:
        raise ValueError(f"Ugyldig horisont: {benchmark.horizon_years}")
    card_nos = [c.card_no for c in cards]
    if len(set(card_nos)) != len(card_nos):
        raise ValueError(f"Duplisert card_no i batchen: {sorted(card_nos)}")
    if set(choices) != set(card_nos):
        raise ValueError(
            f"Valgene må dekke kortene nøyaktig: fikk {sorted(choices)}, "
            f"forventet {sorted(card_nos)}"
        )

    H = benchmark.horizon_years
    r_m = annualize(benchmark.R_m, H)
    r_f = annualize(benchmark.R_f, H)
    alpha_cash = r_f - r_m

    scored: list[CardScore] = []
    hits = 0
    directional = 0
    for card in sorted(cards, key=lambda c: c.card_no):
        choice = choices[card.card_no]
        r = annualize(card.R, H)
        alpha = r - r_m
        a = alpha_contribution(choice, alpha, alpha_cash)
        # Hit rate counts direction calls only (01 §3.2); cash has its own
        # non-scoring avoided-loss marker, applied at the presentation layer.
        if choice != "cash":
            directional += 1
            if a > 0:
                hits += 1
        scored.append(
            CardScore(
                card_no=card.card_no,
                choice=choice,
                R=card.R,
                r=r,
                alpha=alpha,
                a=a,
                points=squash(a, config.tau),
            )
        )

    bonus = config.perfect_bonus if all(c.a > 0 for c in scored) else 0.0
    return JuniorScore(
        score=sum(c.points for c in scored) + bonus,
        bonus=bonus,
        hit_rate=hits / directional if directional else None,
        r_m=r_m,
        r_f=r_f,
        alpha_cash=alpha_cash,
        cards=tuple(scored),
    )


def ideal_junior_choices(
    cards: list[CardTruth], benchmark: BenchmarkTruth
) -> dict[int, str]:
    """The hindsight portfolio (01 §8): long every alpha>0, short every
    alpha<0. Cash is never ex-post optimal — the reveal copy carries the
    ex-ante nuance."""
    r_m = annualize(benchmark.R_m, benchmark.horizon_years)
    return {
        c.card_no: "long"
        if annualize(c.R, benchmark.horizon_years) - r_m > 0
        else "short"
        for c in cards
    }
