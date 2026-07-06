"""Scoring engine tests: the 01 §3.3 golden fixture + the 01 §10 property tests.

The spec table's points are rounded to whole numbers ("eksakte fixtures
genereres av referanseimplementasjonen"), so the golden test asserts against
the table within a ±1 tolerance, and separately freezes this implementation's
exact values to 4 decimals as the regression fixture.
"""

from __future__ import annotations

import pytest

from backend.scoring import (
    BenchmarkTruth,
    CardTruth,
    JuniorScore,
    ideal_junior_choices,
    score_junior,
    squash,
)

# --- The golden fixture (01 §3.3): H=5, R_m=+60 %, R_f=+8 % ------------------

BENCHMARK = BenchmarkTruth(R_m=0.60, R_f=0.08, horizon_years=5)
CARDS = [
    CardTruth(card_no=1, R=1.80),
    CardTruth(card_no=2, R=-0.45),
    CardTruth(card_no=3, R=0.75),
    CardTruth(card_no=4, R=0.10),
    CardTruth(card_no=5, R=3.20),
]
CHOICES = {1: "long", 2: "short", 3: "cash", 4: "long", 5: "short"}


def golden() -> JuniorScore:
    return score_junior(CARDS, CHOICES, BENCHMARK)


class TestGoldenFixture:
    def test_points_match_spec_table(self):
        spec_points = {1: 70, 2: 89, 3: -50, 4: -49, 5: -91}
        result = golden()
        for card in result.cards:
            assert card.points == pytest.approx(spec_points[card.card_no], abs=1.0)

    def test_round_score_hit_rate_and_bonus(self):
        result = golden()
        assert result.score == pytest.approx(-32, abs=1.0)
        assert result.hit_rate == 0.5  # cards 1 and 2 right, 4 and 5 wrong
        assert result.bonus == 0.0

    def test_benchmark_derivations(self):
        result = golden()
        assert result.r_m == pytest.approx(0.099, abs=0.001)
        assert result.r_f == pytest.approx(0.016, abs=0.001)
        assert result.alpha_cash == pytest.approx(-0.083, abs=0.001)

    def test_exact_values_frozen(self):
        """Regression fixture: this implementation's exact outputs (4 dp)."""
        result = golden()
        exact = {c.card_no: round(c.points, 4) for c in result.cards}
        assert exact == {
            1: 70.0014,
            2: 88.7149,
            3: -50.326,
            4: -48.4441,
            5: -91.5297,
        }
        assert round(result.score, 4) == -31.5836
        # alphas as in the spec table (01 §3.3)
        alphas = {c.card_no: round(c.alpha, 4) for c in result.cards}
        assert alphas == {1: 0.1301, 2: -0.2113, 3: 0.0199, 4: -0.0793, 5: 0.2339}

    def test_ideal_choices(self):
        assert ideal_junior_choices(CARDS, BENCHMARK) == {
            1: "long",
            2: "short",
            3: "long",
            4: "short",
            5: "long",
        }


# --- Property tests (01 §10) --------------------------------------------------


class TestProperties:
    def test_long_short_symmetry(self):
        """§10.1: flipping Long<->Short on a card flips its points exactly."""
        as_long = score_junior(CARDS, {**CHOICES, 4: "long"}, BENCHMARK)
        as_short = score_junior(CARDS, {**CHOICES, 4: "short"}, BENCHMARK)
        p_long = next(c.points for c in as_long.cards if c.card_no == 4)
        p_short = next(c.points for c in as_short.cards if c.card_no == 4)
        assert p_long == pytest.approx(-p_short)

    def test_cash_contribution_is_card_independent(self):
        """§10.2: cash scores alpha_cash no matter which card it sits on."""
        all_cash = score_junior(CARDS, dict.fromkeys(CHOICES, "cash"), BENCHMARK)
        points = {c.points for c in all_cash.cards}
        assert len(points) == 1
        assert all_cash.hit_rate is None  # no directional calls to grade

    def test_points_are_bounded(self):
        """§10.3: |p| <= 100 even for a wipe-out and a ten-bagger."""
        extreme_cards = [CardTruth(card_no=1, R=-1.0), CardTruth(card_no=2, R=9.0)]
        result = score_junior(
            extreme_cards, {1: "short", 2: "long"}, BENCHMARK
        )
        for card in result.cards:
            assert abs(card.points) <= 100.0

    def test_score_invariant_under_card_order(self):
        """§10.5: shuffling the card list changes nothing."""
        shuffled = list(reversed(CARDS))
        assert score_junior(shuffled, CHOICES, BENCHMARK) == golden()

    def test_perfect_round_gets_bonus(self):
        perfect = score_junior(CARDS, ideal_junior_choices(CARDS, BENCHMARK), BENCHMARK)
        assert perfect.bonus == 25.0
        assert perfect.score == pytest.approx(
            sum(c.points for c in perfect.cards) + 25.0
        )

    def test_delisting_to_zero_is_max_short_gain(self):
        """§6.1: R=-100 % shorted approaches (but never exceeds) +100 points."""
        result = score_junior(
            [CardTruth(card_no=1, R=-1.0)], {1: "short"}, BENCHMARK
        )
        assert 99.0 < result.cards[0].points <= 100.0


class TestValidation:
    """§6.3: the engine raises on bad input, never guesses."""

    def test_missing_choice(self):
        with pytest.raises(ValueError, match="dekke kortene"):
            score_junior(CARDS, {1: "long"}, BENCHMARK)

    def test_unknown_card_no(self):
        with pytest.raises(ValueError, match="dekke kortene"):
            score_junior(CARDS, {**CHOICES, 99: "long"}, BENCHMARK)

    def test_invalid_choice_value(self):
        with pytest.raises(ValueError, match="Ugyldig valg"):
            score_junior(CARDS, {**CHOICES, 1: "hold"}, BENCHMARK)

    def test_duplicate_card_no(self):
        cards = [CardTruth(card_no=1, R=0.5), CardTruth(card_no=1, R=0.7)]
        with pytest.raises(ValueError, match="Duplisert"):
            score_junior(cards, {1: "long"}, BENCHMARK)

    def test_return_below_total_loss(self):
        with pytest.raises(ValueError, match="under -100"):
            score_junior([CardTruth(card_no=1, R=-1.2)], {1: "long"}, BENCHMARK)

    def test_squash_is_monotone_and_linear_near_zero(self):
        assert squash(0.0) == 0.0
        assert squash(0.01) == pytest.approx(6.66, abs=0.05)  # ~6.7 pts per %-pt
        assert squash(0.2) > squash(0.1) > squash(0.05)
