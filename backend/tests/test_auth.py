"""Auth verifier tests (CP 2.2). No network: conftest's autouse fixture
monkeypatches backend.auth's key resolver to a local ES256 keypair."""

from __future__ import annotations

import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric.ec import (
    SECP256R1,
    generate_private_key,
)

from backend import auth
from backend.tests.conftest import KEY, TEST_USER_ID as USER_ID

OTHER_KEY = generate_private_key(SECP256R1())


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
