"""KAP backend — FastAPI application.

CP 2.3: the loop runs against the database. `/v1/daily` serves the live
daily batch from game_batches/batch_cards, and submit scores from the frozen
truth rows (02 §8.1) and logs game_sessions + decisions (02 §9). All DB
access goes through the Repo dependency — tests inject a FakeRepo.
"""

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse

from backend.auth import AuthError, current_user
from backend.repo import BatchMeta, Repo, TruthRow, get_repo
from backend.schemas import (
    Benchmark,
    DailyBatch,
    Ideal,
    IdealChoice,
    Intro,
    Reveal,
    RevealCard,
    SubmitRequest,
)
from backend.scoring import (
    BenchmarkTruth,
    CardTruth,
    ideal_junior_choices,
    score_junior,
)

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
def daily(
    user_id: str = Depends(current_user),
    repo: Repo = Depends(get_repo),
) -> DailyBatch:
    """Dagens runde fra databasen (05 §4.1). Aldri navn/ticker/epoke."""
    live = repo.get_live_daily()
    if live is None:
        raise HTTPException(status_code=404, detail="Ingen aktiv daglig runde")
    meta, cards = live
    return DailyBatch(
        batch_id=meta.batch_id,
        mode=meta.mode,
        is_daily=True,
        daily_date=str(meta.daily_date),
        horizon_years=meta.horizon_years,
        intro=Intro(**meta.intro),
        cards=cards,
    )


@app.post("/v1/batches/{batch_id}/submit", response_model=Reveal)
def submit(
    batch_id: int,
    request: SubmitRequest,
    user_id: str = Depends(current_user),
    repo: Repo = Depends(get_repo),
) -> Reveal:
    """Scorer valgene mot frossen fasit og logger sesjonen (05 §4.3).

    Ett-forsøk-per-daily (409 + eksisterende reveal) aktiveres i CP 4.2;
    i CP 2.3 er replay fritt (sesjoner logges som øving, is_daily=false).
    """
    meta = repo.get_batch_meta(batch_id)
    if meta is None:
        raise HTTPException(status_code=404, detail="Ukjent batch")
    if meta.status != "live":
        raise HTTPException(status_code=409, detail="Batchen er ikke aktiv")

    truth = repo.get_batch_truth(batch_id)
    expected = {t.card_no for t in truth}
    got = [c.card_no for c in request.choices]
    if sorted(got) != sorted(expected):
        raise HTTPException(
            status_code=400,
            detail=f"Forventet ett valg for hvert av kortene {sorted(expected)}",
        )

    benchmark = BenchmarkTruth(
        R_m=meta.R_m_cum, R_f=meta.R_f_cum, horizon_years=meta.horizon_years
    )
    card_truths = [CardTruth(card_no=t.card_no, R=t.ret_cum) for t in truth]
    result = score_junior(
        card_truths,
        {c.card_no: c.choice for c in request.choices},
        benchmark,
    )
    ideal = ideal_junior_choices(card_truths, benchmark)
    ideal_result = score_junior(card_truths, ideal, benchmark)

    session_id = repo.record_session(
        user_id=user_id,
        batch_id=batch_id,
        mode=meta.mode,
        score=result.score,
        bonus=result.bonus,
        hit_rate=result.hit_rate,
        choices=request.choices,
    )
    return _build_reveal(session_id, meta, truth, result, ideal, ideal_result)


def _build_reveal(
    session_id: int,
    meta: BatchMeta,
    truth: list[TruthRow],
    result,
    ideal: dict[int, str],
    ideal_result,
) -> Reveal:
    """01 §7-kontrakten fra frosne truth-rader + scoringmotorens output."""
    truth_by_no = {t.card_no: t for t in truth}
    return Reveal(
        session_id=session_id,
        score=result.score,
        bonus=result.bonus,
        hit_rate=result.hit_rate,
        benchmark=Benchmark(
            R_m=meta.R_m_cum,
            r_m=result.r_m,
            r_f=result.r_f,
            alpha_cash=result.alpha_cash,
        ),
        decision_date=str(meta.decision_date),
        horizon_years=meta.horizon_years,
        cards=[
            RevealCard(
                card_no=c.card_no,
                ticker=truth_by_no[c.card_no].ticker,
                name=truth_by_no[c.card_no].name,
                choice=c.choice,  # type: ignore[arg-type]  # validert av motoren
                R=c.R,
                r=c.r,
                alpha=c.alpha,
                a=c.a,
                points=c.points,
                clue=truth_by_no[c.card_no].clue,
                event=(
                    None
                    if truth_by_no[c.card_no].event == "none"
                    else truth_by_no[c.card_no].event  # type: ignore[arg-type]
                ),
                company_id=truth_by_no[c.card_no].company_id,
            )
            for c in result.cards
        ],
        ideal=Ideal(
            choices=[
                IdealChoice(card_no=no, choice=choice)  # type: ignore[arg-type]
                for no, choice in sorted(ideal.items())
            ],
            score=ideal_result.score,
        ),
    )
