"""KAP backend — FastAPI application.

CP 0.3: the thinnest possible server. A single health endpoint so the Flutter
client can confirm it reaches the API end-to-end (CP 0.4) before any game
logic, auth, or database exists. The real endpoints (`/v1/daily`, submit, etc.)
are specced in 05_api.md and arrive in later phases.
"""

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

from backend.auth import AuthError, current_user
from backend.fake_data import fake_daily_batch, fake_reveal
from backend.schemas import DailyBatch, Reveal, SubmitRequest

app = FastAPI(title="KAP API", version="0.1.0")


@app.exception_handler(AuthError)
def auth_error_handler(request: Request, exc: AuthError) -> JSONResponse:
    """401 med maskinlesbar 05 §6-konvolutt."""
    return JSONResponse(
        status_code=401,
        content={"error": {"code": "INVALID_TOKEN", "message": exc.message}},
    )


@app.get("/health")
def health() -> dict[str, str]:
    """Liveness probe — returns 200 with a small JSON body."""
    return {"status": "ok"}


@app.get("/v1/daily", response_model=DailyBatch)
def daily(user_id: str = Depends(current_user)) -> DailyBatch:
    """CP 1.1: a hardcoded anonymized daily batch (5 cards).

    Replaced by the real Curator/DB-backed sealed batch in Fase 2/3. Never
    returns name / ticker / decision_date (the anonymization boundary, 05 §5).
    """
    return fake_daily_batch()


@app.post("/v1/batches/{batch_id}/submit", response_model=Reveal)
def submit(
    batch_id: int,
    request: SubmitRequest,
    user_id: str = Depends(current_user),  # brukes til game_sessions i CP 2.3
) -> Reveal:
    """CP 1.2: accept the round's choices and return a hardcoded reveal.

    Stateless for now — no auth, no persistence, no one-attempt-per-daily
    (those arrive with the DB in Fase 2). Validation mirrors 05 §4.3: the batch
    must exist and every card must get exactly one choice.
    """
    batch = fake_daily_batch()
    if batch_id != batch.batch_id:
        raise HTTPException(status_code=404, detail="Ukjent batch")
    expected = {card.card_no for card in batch.cards}
    got = [c.card_no for c in request.choices]
    if sorted(got) != sorted(expected):
        raise HTTPException(
            status_code=400,
            detail=f"Forventet ett valg for hvert av kortene {sorted(expected)}",
        )
    return fake_reveal(request)
