"""API tests for the Fase 1 endpoints: contract shape, the golden round
through the real engine, and the anonymization boundary (05 §5)."""

from __future__ import annotations

import pytest
from fastapi.testclient import TestClient

from backend.main import app

client = TestClient(app)

GOLDEN_CHOICES = {
    "choices": [
        {"card_no": 1, "choice": "long", "response_ms": 3400},
        {"card_no": 2, "choice": "short", "response_ms": 2900},
        {"card_no": 3, "choice": "cash", "response_ms": 4100},
        {"card_no": 4, "choice": "long", "response_ms": 2200},
        {"card_no": 5, "choice": "short", "response_ms": 5000},
    ]
}


def test_daily_requires_auth():
    response = client.get("/v1/daily")
    assert response.status_code == 401
    assert response.json()["error"]["code"] == "INVALID_TOKEN"


def test_submit_requires_auth():
    response = client.post("/v1/batches/1/submit", json=GOLDEN_CHOICES)
    assert response.status_code == 401


def test_daily_rejects_garbage_token():
    response = client.get(
        "/v1/daily", headers={"Authorization": "Bearer not.a.jwt"}
    )
    assert response.status_code == 401


def test_health_stays_open():
    assert client.get("/health").status_code == 200


def test_daily_never_leaks_truth(auth_headers):
    """The GET side must carry no identity or era (05 §5). String-level check
    so a future field rename can't smuggle truth past a key-name test."""
    response = client.get("/v1/daily", headers=auth_headers)
    assert response.status_code == 200
    body = response.text.lower()
    for leak in ("ticker", '"name"', "corex", "meridian", "halvex",
                 "sterling", "brightloom", "decision_date", "alpha", "clue"):
        assert leak not in body, f"anonymiseringsbrudd: {leak!r} i GET /v1/daily"
    assert len(response.json()["cards"]) == 5


def test_submit_scores_the_golden_round(auth_headers):
    """The fake batch *is* the 01 §3.3 fixture — submit must reproduce it."""
    response = client.post(
        "/v1/batches/1/submit", json=GOLDEN_CHOICES, headers=auth_headers
    )
    assert response.status_code == 200
    reveal = response.json()

    assert reveal["score"] == pytest.approx(-32, abs=1.0)
    assert reveal["hit_rate"] == 0.5
    assert reveal["bonus"] == 0.0
    spec_points = {1: 70, 2: 89, 3: -50, 4: -49, 5: -91}
    for card in reveal["cards"]:
        assert card["points"] == pytest.approx(spec_points[card["card_no"]], abs=1.0)

    # Truth appears here and only here.
    assert reveal["cards"][0]["ticker"] == "CORX"
    assert reveal["decision_date"] == "2014-06-02"
    # The ideal round earns the perfect bonus on top of five positive cards.
    assert reveal["ideal"]["score"] > 100


def test_submit_rejects_incomplete_choices(auth_headers):
    response = client.post(
        "/v1/batches/1/submit",
        json={"choices": [{"card_no": 1, "choice": "long"}]},
        headers=auth_headers,
    )
    assert response.status_code == 400


def test_submit_rejects_unknown_batch(auth_headers):
    response = client.post(
        "/v1/batches/99/submit", json=GOLDEN_CHOICES, headers=auth_headers
    )
    assert response.status_code == 404


def test_submit_rejects_invalid_choice_value(auth_headers):
    bad = {"choices": [{**c, "choice": "hold"} for c in GOLDEN_CHOICES["choices"]]}
    response = client.post("/v1/batches/1/submit", json=bad, headers=auth_headers)
    assert response.status_code == 422  # Pydantic Literal validation


def test_submit_records_session_and_decisions(auth_headers, fake_repo):
    """CP 2.3: submit is the source of game_sessions + decisions (05 §4.3)."""
    from backend.tests.conftest import TEST_USER_ID

    response = client.post(
        "/v1/batches/1/submit", json=GOLDEN_CHOICES, headers=auth_headers
    )
    assert response.status_code == 200

    (session,) = fake_repo.sessions
    assert session["user_id"] == TEST_USER_ID
    assert session["batch_id"] == 1
    assert session["score"] == pytest.approx(-31.58, abs=0.1)
    assert session["hit_rate"] == 0.5
    assert [c.card_no for c in session["choices"]] == [1, 2, 3, 4, 5]
    assert session["choices"][2].response_ms == 4100
    # session_id i reveal kommer fra DB-innsettingen
    assert response.json()["session_id"] == 1


def test_submit_rejects_non_live_batch(auth_headers, fake_repo):
    fake_repo.status = "sealed"
    response = client.post(
        "/v1/batches/1/submit", json=GOLDEN_CHOICES, headers=auth_headers
    )
    assert response.status_code == 409


def test_daily_serves_batch_metadata_from_repo(auth_headers):
    body = client.get("/v1/daily", headers=auth_headers).json()
    assert body["horizon_years"] == 5
    assert body["intro"]["market_sentiment"] == "grådig"
    assert body["is_daily"] is True


def test_daily_404_when_no_live_batch(auth_headers, fake_repo):
    fake_repo.status = "archived"
    response = client.get("/v1/daily", headers=auth_headers)
    assert response.status_code == 404
