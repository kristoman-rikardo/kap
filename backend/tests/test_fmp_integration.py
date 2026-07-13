"""Live FMP checkpoint (CP 3.1). Env-gated on FMP_API_KEY (.env, gitignored).

This is the checkpoint itself: a real call fetches AAPL income-statement, and
a deliberately gated endpoint raises PremiumGatedError instead of skipping.
"""

from __future__ import annotations

import os

import pytest
from dotenv import load_dotenv

from backend.fmp import FMPClient, PremiumGatedError

load_dotenv()

pytestmark = pytest.mark.skipif(
    not os.environ.get("FMP_API_KEY"), reason="FMP_API_KEY not configured"
)


@pytest.fixture
def client() -> FMPClient:
    return FMPClient(key=os.environ["FMP_API_KEY"])


def test_income_statement_real(client):
    rows = client.get(
        "income-statement", symbol="AAPL", period="annual", limit=1
    )
    assert isinstance(rows, list) and rows
    row = rows[0]
    assert row["symbol"] == "AAPL"
    assert "filingDate" in row  # look-ahead anchor (02 §3.1)
    assert row.get("revenue")


def test_gated_endpoint_raises(client):
    # earning-call-transcript requires Ultimate (05 §8.7) -> 402.
    with pytest.raises(PremiumGatedError) as exc:
        client.get(
            "earning-call-transcript", symbol="AAPL", year=2023, quarter=1
        )
    assert exc.value.path == "earning-call-transcript"
