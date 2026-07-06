"""Supabase JWT verification (CP 2.2, 05 §3).

The project signs access tokens with ES256; the public keys are served at
{SUPABASE_URL}/auth/v1/.well-known/jwks.json. PyJWKClient fetches and caches
them. `_signing_key_for` is the only networked piece — tests monkeypatch it.
"""

from __future__ import annotations

import os
from functools import lru_cache

import jwt
from dotenv import load_dotenv
from fastapi import Request

load_dotenv()


class AuthError(Exception):
    """Any authentication failure -> 401 with the 05 §6 envelope."""

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


@lru_cache
def _jwks_client() -> jwt.PyJWKClient:
    url = os.environ.get("SUPABASE_URL")
    if not url:
        raise RuntimeError("SUPABASE_URL mangler (sett den i .env)")
    return jwt.PyJWKClient(f"{url}/auth/v1/.well-known/jwks.json")


def _signing_key_for(token: str):
    """Resolve the public key for this token's kid via JWKS (network)."""
    return _jwks_client().get_signing_key_from_jwt(token).key


def verify_token(token: str) -> str:
    """Verify signature/exp/aud and return the user id (sub claim)."""
    try:
        key = _signing_key_for(token)
        payload = jwt.decode(
            token, key, algorithms=["ES256"], audience="authenticated"
        )
    except AuthError:
        raise
    except jwt.PyJWTError as exc:
        raise AuthError(f"Ugyldig token: {exc}") from exc
    sub = payload.get("sub")
    if not sub:
        raise AuthError("Token mangler sub-claim")
    return sub


def current_user(request: Request) -> str:
    """FastAPI-dependency: krever `Authorization: Bearer <jwt>` (05 §4)."""
    header = request.headers.get("Authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise AuthError("Mangler bearer-token")
    return verify_token(token)
