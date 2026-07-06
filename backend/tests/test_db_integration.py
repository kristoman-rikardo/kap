"""Integration tests against the hosted Supabase project (CP 2.3).

Env-gated: skipped unless SUPABASE_DB_URL and SUPABASE_URL are configured
(they live in the repo-root .env, loaded via dotenv). These tests hit the
real database and clean up after themselves.

The RLS test is the checkpoint's security proof: two anonymous users — each
sees only their own sessions/decisions via PostgREST, and batch_cards (the
answer sheet) is unreachable for both.
"""

from __future__ import annotations

import os

import pytest
from dotenv import load_dotenv
from fastapi.testclient import TestClient

load_dotenv()

pytestmark = pytest.mark.skipif(
    not (os.environ.get("SUPABASE_DB_URL") and os.environ.get("SUPABASE_URL")),
    reason="hosted DB not configured",
)

GOLDEN_CHOICES = [
    {"card_no": 1, "choice": "long"},
    {"card_no": 2, "choice": "short"},
    {"card_no": 3, "choice": "cash"},
    {"card_no": 4, "choice": "long"},
    {"card_no": 5, "choice": "short"},
]

PUBLISHABLE_KEY = "sb_publishable_ovn2VI5j5QtQcuQ8MNrM5A_VoNTRXWy"


def anon_user() -> tuple[str, str]:
    """Create a real anonymous auth user (auth.users row + profile via the
    signup trigger). profiles has a hard FK to auth.users, so a direct
    insert is impossible — which is itself schema working as designed."""
    import httpx

    resp = httpx.post(
        f"{os.environ['SUPABASE_URL']}/auth/v1/signup",
        headers={"apikey": PUBLISHABLE_KEY},
        json={},
    )
    assert resp.status_code == 200, resp.text
    data = resp.json()
    return data["user"]["id"], data["access_token"]


@pytest.fixture
def pg():
    from backend.db import pool

    with pool().connection() as conn:
        yield conn


@pytest.fixture
def temp_profile(pg):
    """A throwaway real anonymous user; deleting from auth.users cascades
    through profiles -> game_sessions -> decisions."""
    user_id, _token = anon_user()
    yield user_id
    pg.execute("delete from auth.users where id = %s", (user_id,))
    pg.commit()


def test_pg_repo_serves_seeded_batch():
    from backend.repo import PgRepo

    repo = PgRepo()
    live = repo.get_live_daily()
    assert live is not None, "kjør `uv run python -m backend.seed` først"
    meta, cards = live
    assert meta.horizon_years == 5
    assert meta.intro["market_sentiment"] == "grådig"
    assert [c.card_no for c in cards] == [1, 2, 3, 4, 5]

    truth = repo.get_batch_truth(meta.batch_id)
    corx = next(t for t in truth if t.ticker == "CORX")
    assert corx.ret_cum == pytest.approx(1.80)
    assert corx.name == "Corex Systems"


def test_full_api_against_hosted_db(auth_headers, fake_repo, temp_profile, pg):
    """The whole loop against Postgres: daily -> submit -> rows in the log.

    conftest's FakeRepo override is removed for this test; auth still uses
    the local keypair (we test the DB layer, not Supabase auth here).
    """
    import time

    import jwt as pyjwt

    from backend.main import app
    from backend.repo import get_repo
    from backend.tests.conftest import KEY

    app.dependency_overrides.pop(get_repo, None)  # bruk ekte PgRepo
    client = TestClient(app)
    now = int(time.time())
    token = pyjwt.encode(
        {"sub": temp_profile, "aud": "authenticated", "iat": now, "exp": now + 600},
        KEY,
        algorithm="ES256",
    )
    headers = {"Authorization": f"Bearer {token}"}

    body = client.get("/v1/daily", headers=headers).json()
    batch_id = body["batch_id"]
    assert len(body["cards"]) == 5
    assert "ticker" not in str(body).lower()

    reveal = client.post(
        f"/v1/batches/{batch_id}/submit",
        json={"choices": GOLDEN_CHOICES},
        headers=headers,
    ).json()
    assert reveal["score"] == pytest.approx(-31.58, abs=0.1)
    session_id = reveal["session_id"]

    try:
        rows = pg.execute(
            """select d.card_no, d.choice from decisions d
               join game_sessions s on s.id = d.session_id
               where s.id = %s and s.user_id = %s order by d.card_no""",
            (session_id, temp_profile),
        ).fetchall()
        assert [(r[0], r[1]) for r in rows] == [
            (1, "long"), (2, "short"), (3, "cash"), (4, "long"), (5, "short"),
        ]
    finally:
        pg.execute("delete from game_sessions where id = %s", (session_id,))
        pg.commit()


def test_rls_users_see_only_their_own_rows(pg):
    """Checkpoint proof (02 §10): own rows only; batch_cards unreachable."""
    import httpx

    base = os.environ["SUPABASE_URL"]

    def rest(path: str, token: str):
        return httpx.get(
            f"{base}/rest/v1/{path}",
            headers={
                "apikey": PUBLISHABLE_KEY,
                "Authorization": f"Bearer {token}",
            },
        ).json()

    user_a, token_a = anon_user()
    user_b, token_b = anon_user()

    # Service-siden logger en sesjon for A (som FastAPI gjør ved submit).
    session_id = pg.execute(
        """insert into game_sessions (user_id, batch_id, mode, is_daily, score)
           values (%s, 1, 'junior', false, -31.58) returning id""",
        (user_a,),
    ).fetchone()[0]
    pg.execute(
        """insert into decisions (session_id, card_no, choice)
           values (%s, 1, 'long')""",
        (session_id,),
    )
    pg.commit()

    try:
        a_sessions = rest("game_sessions?select=id,user_id", token_a)
        b_sessions = rest("game_sessions?select=id,user_id", token_b)
        assert [s["id"] for s in a_sessions] == [session_id]  # A ser sin egen
        assert b_sessions == []  # B ser ingenting

        a_decisions = rest("decisions?select=card_no,choice", token_a)
        assert a_decisions == [{"card_no": 1, "choice": "long"}]
        assert rest("decisions?select=card_no", token_b) == []

        # Fasit-tabellen er stengt for klienter — uansett bruker.
        assert rest("batch_cards?select=name,alpha", token_a) == []
        assert rest("batch_cards?select=name,alpha", token_b) == []
    finally:
        pg.execute(
            "delete from auth.users where id in (%s, %s)", (user_a, user_b)
        )  # cascade: profiles -> game_sessions -> decisions
        pg.commit()
