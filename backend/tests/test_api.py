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
