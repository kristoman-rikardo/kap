"""Shared API-test doubles: a local ES256 keypair stands in for Supabase
JWKS, and a FakeRepo (built from the golden fixture in fake_data) stands in
for Postgres — unit tests never touch the network."""

from __future__ import annotations

import datetime as dt
import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric.ec import (
    SECP256R1,
    generate_private_key,
)

from backend import auth
from backend.fake_data import _HORIZON_YEARS, _R_F, _R_M, _TRUTH, fake_daily_batch
from backend.repo import BatchMeta, SessionRow, TruthRow, get_repo
from backend.schemas import Card, ChoiceIn

KEY = generate_private_key(SECP256R1())
PUBLIC_KEY = KEY.public_key()
TEST_USER_ID = "11111111-2222-3333-4444-555555555555"


@pytest.fixture(autouse=True)
def fake_jwks(monkeypatch):
    monkeypatch.setattr(auth, "_signing_key_for", lambda token: PUBLIC_KEY)


@pytest.fixture
def auth_headers() -> dict[str, str]:
    now = int(time.time())
    token = jwt.encode(
        {"sub": TEST_USER_ID, "aud": "authenticated", "iat": now, "exp": now + 3600},
        KEY,
        algorithm="ES256",
    )
    return {"Authorization": f"Bearer {token}"}


class FakeRepo:
    """In-memory Repo mirroring the seeded golden-fixture batch (02 §15)."""

    def __init__(self) -> None:
        self.status = "live"
        self.sessions: list[dict] = []
        batch = fake_daily_batch()
        self._cards: list[Card] = batch.cards
        self._meta_kwargs = dict(
            batch_id=1,
            mode="junior",
            decision_date=dt.date(2014, 6, 2),
            horizon_years=_HORIZON_YEARS,
            daily_date=dt.date.today(),
            R_m_cum=_R_M,
            R_f_cum=_R_F,
            intro=batch.intro.model_dump(),
        )

    def _meta(self) -> BatchMeta:
        return BatchMeta(status=self.status, **self._meta_kwargs)

    def get_live_daily(self):
        return (self._meta(), self._cards) if self.status == "live" else None

    def get_batch_meta(self, batch_id: int):
        return self._meta() if batch_id == 1 else None

    def get_batch_truth(self, batch_id: int) -> list[TruthRow]:
        return [
            TruthRow(
                card_no=no,
                company_id=cid,
                ticker=ticker,
                name=name,
                ret_cum=R,
                clue=clue,
                event="none",
            )
            for no, ticker, name, cid, R, clue in _TRUTH
        ]

    def record_session(
        self,
        user_id: str,
        batch_id: int,
        mode: str,
        score: float,
        bonus: float,
        hit_rate: float | None,
        choices: list[ChoiceIn],
    ) -> int:
        self.sessions.append(
            {
                "user_id": user_id,
                "batch_id": batch_id,
                "mode": mode,
                "score": score,
                "bonus": bonus,
                "hit_rate": hit_rate,
                "choices": choices,
            }
        )
        return len(self.sessions)

    def get_user_sessions(
        self, user_id: str, limit: int = 100
    ) -> list[SessionRow]:
        return [
            SessionRow(
                session_id=i + 1,
                batch_id=s["batch_id"],
                daily_date=self._meta_kwargs["daily_date"],
                submitted_at=dt.datetime.now(dt.timezone.utc),
                score=s["score"],
                bonus=s["bonus"],
                hit_rate=s["hit_rate"],
            )
            for i, s in enumerate(self.sessions)
            if s["user_id"] == user_id
        ][::-1][:limit]


@pytest.fixture(autouse=True)
def fake_repo():
    """Route all endpoint DB access through the in-memory repo."""
    from backend.main import app

    repo = FakeRepo()
    app.dependency_overrides[get_repo] = lambda: repo
    yield repo
    app.dependency_overrides.pop(get_repo, None)
