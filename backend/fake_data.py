"""Hardcoded fake data for the skeleton phase (Fase 1).

One deterministic daily batch so the app's game loop can be built and swiped
before the real Curator/pipeline exists (00_fremgangsmåte CP 1.1). Replaced by
DB-backed, sealed batches in Fase 2/3.

The rate/inflation/GDP regime is shared across all five cards (one macro picture
per batch — Instructions §3 / 04 §5.6); only `sector_sentiment` varies per card.
Every value is banded/relative and anonymized — no names, tickers, amounts, or
year (04 §5.7).
"""

from __future__ import annotations

from backend.schemas import (
    Benchmark,
    Card,
    CardPayload,
    ChoiceValue,
    DailyBatch,
    Fundamentals,
    Growth,
    Ideal,
    IdealChoice,
    Intro,
    Macro,
    Reveal,
    RevealCard,
    SubmitRequest,
)


def _macro(sector_sentiment: str) -> Macro:
    """Shared regime + a per-card sector sentiment."""
    return Macro(
        rate_level="lav",
        rate_direction="fallende",
        inflation_band="moderat",
        gdp_band="sunn",
        sector_sentiment=sector_sentiment,
    )


_CARDS: list[Card] = [
    Card(
        card_no=1,
        payload=CardPayload(
            macro=_macro("optimistisk"),
            fundamentals=Fundamentals(
                pe=18.4,
                ps=3.1,
                debt_to_equity=0.6,
                gross_margin=0.41,
                operating_margin=0.22,
                net_margin=0.15,
                roic=0.19,
            ),
            growth=Growth(rev_cagr_3y=0.12, eps_cagr_3y=0.09),
            cap="mid",
            sector_coarse="Teknologi",
            narrative=(
                "Selskapet vokser raskt i et marked med sterk etterspørsel etter "
                "digitale tjenester. Marginene presses noe av tunge investeringer "
                "i ny kapasitet."
            ),
        ),
    ),
    Card(
        card_no=2,
        payload=CardPayload(
            macro=_macro("nøytral"),
            fundamentals=Fundamentals(
                pe=9.2,
                ps=1.1,
                debt_to_equity=1.3,
                gross_margin=0.34,
                operating_margin=0.19,
                net_margin=0.11,
                roic=0.13,
            ),
            growth=Growth(rev_cagr_3y=0.04, eps_cagr_3y=0.02),
            cap="large",
            sector_coarse="Energi",
            narrative=(
                "En moden aktør i en syklisk råvarebransje med stabile "
                "kontantstrømmer. Høy gjeldsgrad gjør resultatet følsomt for "
                "rentekostnader."
            ),
        ),
    ),
    Card(
        card_no=3,
        payload=CardPayload(
            macro=_macro("optimistisk"),
            fundamentals=Fundamentals(
                pe=24.1,
                ps=5.2,
                debt_to_equity=0.4,
                gross_margin=0.68,
                operating_margin=0.29,
                net_margin=0.21,
                roic=0.22,
            ),
            growth=Growth(rev_cagr_3y=0.08, eps_cagr_3y=0.10),
            cap="large",
            sector_coarse="Helse",
            narrative=(
                "Stabil etterspørsel og sterke marginer kjennetegner en defensiv "
                "virksomhet. Et nært forestående patentutløp skaper usikkerhet om "
                "fremtidig inntjening."
            ),
        ),
    ),
    Card(
        card_no=4,
        payload=CardPayload(
            macro=_macro("pessimistisk"),
            fundamentals=Fundamentals(
                pe=None,  # negativ EPS -> vises som "neg." (04 §5.2)
                ps=2.4,
                debt_to_equity=0.9,
                gross_margin=0.52,
                operating_margin=-0.05,
                net_margin=-0.08,
                roic=-0.04,
            ),
            growth=Growth(rev_cagr_3y=0.31, eps_cagr_3y=0.0),
            cap="small",
            sector_coarse="Forbruksvarer",
            narrative=(
                "Et raskt voksende selskap som ennå ikke tjener penger. Veksten er "
                "imponerende, men veien til lønnsomhet er uklar."
            ),
        ),
    ),
    Card(
        card_no=5,
        payload=CardPayload(
            macro=_macro("nøytral"),
            fundamentals=Fundamentals(
                pe=11.5,
                ps=2.9,
                debt_to_equity=1.1,
                gross_margin=0.60,
                operating_margin=0.40,
                net_margin=0.28,
                roic=0.12,
            ),
            growth=Growth(rev_cagr_3y=0.06, eps_cagr_3y=0.07),
            cap="mid",
            sector_coarse="Finans",
            narrative=(
                "En veletablert finansaktør med solid utbyttekapasitet. "
                "Inntjeningen er følsom for renteutviklingen og for kredittap i en "
                "nedgangskonjunktur."
            ),
        ),
    ),
]


def fake_daily_batch() -> DailyBatch:
    """The single fake daily round served by GET /v1/daily during Fase 1."""
    return DailyBatch(
        batch_id=1,
        mode="junior",
        is_daily=True,
        daily_date="2026-06-20",
        horizon_years=5,
        intro=Intro(
            market_sentiment="grådig",
            rate_picture="lave, fallende renter",
            note=(
                "Du går inn i et marked preget av optimisme og fallende renter. "
                "Vurder hvert selskap på tallene alene."
            ),
        ),
        cards=_CARDS,
    )


# --- Truth for the fake batch (only ever exposed via submit, 05 §5) ----------
#
# The cumulative returns are the golden fixture from 01 §3.3 (H=5, R_m=+60 %,
# R_f=+8 %), card for card. When the real scoring engine lands (CP 1.3) the
# fake round therefore *is* the fixture, and a Long/Short/Cash/Long/Short round
# must reproduce the spec table (points ≈ +70/+89/−50/−49/−91, score ≈ −32).

_HORIZON_YEARS = 5
_R_M = 0.60  # cumulative benchmark total return
_R_F = 0.08  # cumulative risk-free return

# (card_no, ticker, name, company_id, R cumulative, clue)
_TRUTH: list[tuple[int, str, str, int, float, str]] = [
    (
        1,
        "CORX",
        "Corex Systems",
        101,
        1.80,
        "Høy ROIC og tosifret vekst til moderat prising – investeringene "
        "ble til varig inntjening.",
    ),
    (
        2,
        "MERI",
        "Meridian Energy Partners",
        102,
        -0.45,
        "Høy gearing ble tung å bære da råvareprisene snudde ned.",
    ),
    (
        3,
        "HLVX",
        "Halvex Pharmaceuticals",
        103,
        0.75,
        "Defensiv inntjening holdt følge med markedet – patentutløpet ble "
        "dekket av nye produkter.",
    ),
    (
        4,
        "BLOM",
        "Brightloom Brands",
        104,
        0.10,
        "Veksten fortsatte, men lønnsomheten kom aldri – aksjen ble stående "
        "igjen i et stigende marked.",
    ),
    (
        5,
        "SCF",
        "Sterling Crest Financial",
        105,
        3.20,
        "Solid inntjeningsmaskin til lav prising – markedet priset om "
        "aksjen da marginene løftet seg.",
    ),
]


def _annualized(R: float) -> float:
    return (1.0 + R) ** (1.0 / _HORIZON_YEARS) - 1.0


def _stub_points(a: float) -> float:
    """CP 1.2 placeholder: linear in the alpha contribution.

    Replaced by the real tanh point mapping (01 §2) in CP 1.3 — this exists
    only so the reveal screen has plausible numbers to render.
    """
    return round(a * 500.0)


def fake_reveal(request: SubmitRequest) -> Reveal:
    """CP 1.2: a reveal built from hardcoded truth with stub scoring.

    The response *shape* is the locked 01 §7 contract; only the point
    computation is a placeholder until the scoring engine (CP 1.3).
    """
    r_m = _annualized(_R_M)
    r_f = _annualized(_R_F)
    alpha_cash = r_f - r_m
    choice_by_card: dict[int, ChoiceValue] = {
        c.card_no: c.choice for c in request.choices
    }

    cards: list[RevealCard] = []
    hits = 0
    directional = 0
    for card_no, ticker, name, company_id, R, clue in _TRUTH:
        choice = choice_by_card[card_no]
        r = _annualized(R)
        alpha = r - r_m
        if choice == "long":
            a = alpha
        elif choice == "short":
            a = -alpha
        else:
            a = alpha_cash
        if choice != "cash":
            directional += 1
            if a > 0:
                hits += 1
        cards.append(
            RevealCard(
                card_no=card_no,
                ticker=ticker,
                name=name,
                choice=choice,
                R=R,
                r=r,
                alpha=alpha,
                a=a,
                points=_stub_points(a),
                clue=clue,
                event=None,
                company_id=company_id,
            )
        )

    ideal_choices = [
        IdealChoice(
            card_no=card_no, choice="long" if _annualized(R) - r_m > 0 else "short"
        )
        for card_no, _, _, _, R, _ in _TRUTH
    ]
    ideal_score = sum(
        _stub_points(abs(_annualized(R) - r_m)) for _, _, _, _, R, _ in _TRUTH
    )

    return Reveal(
        session_id=1,
        score=sum(c.points for c in cards),
        bonus=0.0,
        hit_rate=hits / directional if directional else None,
        benchmark=Benchmark(R_m=_R_M, r_m=r_m, r_f=r_f, alpha_cash=alpha_cash),
        decision_date="2014-06-02",
        horizon_years=_HORIZON_YEARS,
        cards=cards,
        ideal=Ideal(choices=ideal_choices, score=ideal_score),
    )
