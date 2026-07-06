"""Shared API-test auth: a local ES256 keypair stands in for Supabase JWKS."""

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
