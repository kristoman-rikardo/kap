"""Auth verifier tests (CP 2.2). No network: an ES256 keypair is generated
here and backend.auth's key resolver is monkeypatched (via conftest's
autouse fixture once Task 2 lands; locally here for Task 1)."""

from __future__ import annotations

import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric.ec import (
    SECP256R1,
    generate_private_key,
)

from backend import auth

KEY = generate_private_key(SECP256R1())
PUBLIC_KEY = KEY.public_key()
OTHER_KEY = generate_private_key(SECP256R1())

USER_ID = "11111111-2222-3333-4444-555555555555"


def make_token(
    *,
    sub: str = USER_ID,
    aud: str = "authenticated",
    exp_offset: int = 3600,
    key=KEY,
) -> str:
    now = int(time.time())
    return jwt.encode(
        {"sub": sub, "aud": aud, "iat": now, "exp": now + exp_offset},
        key,
        algorithm="ES256",
    )


@pytest.fixture(autouse=True)
def fake_jwks(monkeypatch):
    monkeypatch.setattr(auth, "_signing_key_for", lambda token: PUBLIC_KEY)


def test_valid_token_returns_sub():
    assert auth.verify_token(make_token()) == USER_ID


def test_expired_token_rejected():
    with pytest.raises(auth.AuthError):
        auth.verify_token(make_token(exp_offset=-60))


def test_wrong_audience_rejected():
    with pytest.raises(auth.AuthError):
        auth.verify_token(make_token(aud="anon"))


def test_wrong_key_rejected():
    with pytest.raises(auth.AuthError):
        auth.verify_token(make_token(key=OTHER_KEY))


def test_garbage_token_rejected():
    with pytest.raises(auth.AuthError):
        auth.verify_token("not.a.jwt")


def test_missing_sub_rejected():
    token = jwt.encode(
        {"aud": "authenticated", "exp": int(time.time()) + 3600},
        KEY,
        algorithm="ES256",
    )
    with pytest.raises(auth.AuthError):
        auth.verify_token(token)
