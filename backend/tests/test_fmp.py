"""FMP client tests (CP 3.1) — hermetic: fake session + fake clock, no
network, no real sleeps. The live checkpoint lives in test_fmp_integration."""

from __future__ import annotations

import pytest

from backend.fmp import (
    AuthError,
    FMPClient,
    FMPServerError,
    PremiumGatedError,
    RateLimitError,
)


class FakeResponse:
    def __init__(self, status_code: int, json_data=None):
        self.status_code = status_code
        self._json = json_data if json_data is not None else {}

    def json(self):
        return self._json


class FakeSession:
    """Returns queued responses in order; records each request."""

    def __init__(self, responses):
        self._responses = list(responses)
        self.calls: list[dict] = []

    def get(self, url, params=None, headers=None, timeout=None):
        self.calls.append(
            {"url": url, "params": params, "headers": headers, "timeout": timeout}
        )
        return self._responses.pop(0)


def _client(responses, **kw):
    """Client wired to a fake session, a no-op sleep and a fake clock so time
    is fully controlled."""
    clock = [0.0]
    sleeps: list[float] = []

    def sleep(dt):
        sleeps.append(dt)
        clock[0] += dt

    session = FakeSession(responses)
    client = FMPClient(
        key="k",
        session=session,
        sleep=sleep,
        monotonic=lambda: clock[0],
        **kw,
    )
    client._test_session = session  # type: ignore[attr-defined]
    client._test_sleeps = sleeps  # type: ignore[attr-defined]
    return client


# --- Task 1: status dispatch ------------------------------------------------


def test_get_returns_json_on_200():
    client = _client([FakeResponse(200, [{"symbol": "AAPL", "revenue": 1}])])
    data = client.get("income-statement", symbol="AAPL", period="annual")
    assert data == [{"symbol": "AAPL", "revenue": 1}]

    call = client._test_session.calls[0]
    assert call["url"].endswith("/stable/income-statement")
    assert call["headers"]["apikey"] == "k"
    assert call["params"]["symbol"] == "AAPL"
    assert call["params"]["period"] == "annual"


def test_402_raises_premium_gated_with_path():
    client = _client([FakeResponse(402, {"Error Message": "Restricted Endpoint"})])
    with pytest.raises(PremiumGatedError) as exc:
        client.get("earning-call-transcript", symbol="AAPL")
    assert exc.value.path == "earning-call-transcript"


def test_401_raises_auth():
    client = _client([FakeResponse(401, {"Error Message": "Invalid API KEY"})])
    with pytest.raises(AuthError):
        client.get("income-statement", symbol="AAPL")


def test_403_raises_auth():
    client = _client([FakeResponse(403, {})])
    with pytest.raises(AuthError):
        client.get("income-statement", symbol="AAPL")


# --- Task 2: retry/backoff (written now, pass after Task 2) -----------------


def test_retries_on_429_then_succeeds():
    client = _client(
        [FakeResponse(429), FakeResponse(429), FakeResponse(200, [{"ok": 1}])],
        backoff_base=0.5,
    )
    assert client.get("income-statement", symbol="AAPL") == [{"ok": 1}]
    assert client._test_sleeps == [0.5, 1.0]  # doubling


def test_429_exhausted_raises_rate_limit():
    client = _client(
        [FakeResponse(429), FakeResponse(429), FakeResponse(429)],
        max_retries=3,
        backoff_base=0.1,
    )
    with pytest.raises(RateLimitError):
        client.get("income-statement", symbol="AAPL")


def test_5xx_retried_then_raises_server_error():
    client = _client(
        [FakeResponse(500), FakeResponse(503), FakeResponse(500)],
        max_retries=3,
        backoff_base=0.1,
    )
    with pytest.raises(FMPServerError):
        client.get("income-statement", symbol="AAPL")


def test_503_then_success():
    client = _client([FakeResponse(503), FakeResponse(200, {"ok": 1})])
    assert client.get("income-statement", symbol="AAPL") == {"ok": 1}
