"""Repository layer (CP 2.3): the only place game SQL lives.

Endpoints depend on the `Repo` protocol via FastAPI's dependency system;
tests inject a FakeRepo (conftest). `PgRepo` reads the sealed/frozen game
tables (02 §8) and writes the session log (02 §9) — public payloads out,
truth only for scoring, everything user-generated in one transaction.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import date
from typing import Protocol

from psycopg.rows import dict_row
from psycopg.types.json import Jsonb

from backend.db import pool
from backend.schemas import Card, ChoiceIn


@dataclass(frozen=True)
class BatchMeta:
    batch_id: int
    mode: str
    status: str
    decision_date: date
    horizon_years: int
    daily_date: date | None
    R_m_cum: float
    R_f_cum: float
    intro: dict


@dataclass(frozen=True)
class TruthRow:
    card_no: int
    company_id: int
    ticker: str
    name: str
    ret_cum: float
    clue: str
    event: str  # 'none' | 'delisted' | 'acquired' (02 §8)


class Repo(Protocol):
    def get_live_daily(self) -> tuple[BatchMeta, list[Card]] | None: ...

    def get_batch_meta(self, batch_id: int) -> BatchMeta | None: ...

    def get_batch_truth(self, batch_id: int) -> list[TruthRow]: ...

    def record_session(
        self,
        user_id: str,
        batch_id: int,
        mode: str,
        score: float,
        bonus: float,
        hit_rate: float | None,
        choices: list[ChoiceIn],
    ) -> int: ...


_META_COLS = """
    id, mode, status, decision_date, horizon_years, daily_date,
    r_m_cum, r_f_cum, intro
"""


def _meta_from(row: dict) -> BatchMeta:
    return BatchMeta(
        batch_id=row["id"],
        mode=row["mode"],
        status=row["status"],
        decision_date=row["decision_date"],
        horizon_years=row["horizon_years"],
        daily_date=row["daily_date"],
        R_m_cum=float(row["r_m_cum"]),
        R_f_cum=float(row["r_f_cum"]),
        intro=row["intro"] or {},
    )


class PgRepo:
    """Postgres implementation. Service role — RLS does not apply here."""

    def get_live_daily(self) -> tuple[BatchMeta, list[Card]] | None:
        with pool().connection() as conn, conn.cursor(row_factory=dict_row) as cur:
            row = cur.execute(
                f"""select {_META_COLS} from game_batches
                    where is_daily and status = 'live' and daily_date <= current_date
                    order by daily_date desc limit 1"""
            ).fetchone()
            if row is None:
                return None
            cards = cur.execute(
                """select card_no, public_payload from batch_cards
                   where batch_id = %s order by card_no""",
                (row["id"],),
            ).fetchall()
        return _meta_from(row), [
            Card(card_no=c["card_no"], payload=c["public_payload"]) for c in cards
        ]

    def get_batch_meta(self, batch_id: int) -> BatchMeta | None:
        with pool().connection() as conn, conn.cursor(row_factory=dict_row) as cur:
            row = cur.execute(
                f"select {_META_COLS} from game_batches where id = %s", (batch_id,)
            ).fetchone()
        return None if row is None else _meta_from(row)

    def get_batch_truth(self, batch_id: int) -> list[TruthRow]:
        with pool().connection() as conn, conn.cursor(row_factory=dict_row) as cur:
            rows = cur.execute(
                """select bc.card_no, bc.company_id, c.ticker, bc.name,
                          bc.ret_cum, bc.clue, bc.event
                   from batch_cards bc join companies c on c.id = bc.company_id
                   where bc.batch_id = %s order by bc.card_no""",
                (batch_id,),
            ).fetchall()
        return [
            TruthRow(
                card_no=r["card_no"],
                company_id=r["company_id"],
                ticker=r["ticker"],
                name=r["name"],
                ret_cum=float(r["ret_cum"]),
                clue=r["clue"] or "",
                event=r["event"],
            )
            for r in rows
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
        # is_daily=False i CP 2.3: fri replay i dev; ett-forsøk-håndhevelsen
        # (409 + eksisterende reveal, 05 §4.3) aktiveres i CP 4.2.
        with pool().connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """insert into game_sessions
                         (user_id, batch_id, mode, is_daily, submitted_at,
                          score, bonus, hit_rate)
                       values (%s, %s, %s, false, now(), %s, %s, %s)
                       returning id""",
                    (user_id, batch_id, mode, score, bonus, hit_rate),
                )
                session_id: int = cur.fetchone()[0]
                cur.executemany(
                    """insert into decisions
                         (session_id, card_no, choice, weight, response_ms)
                       values (%s, %s, %s, %s, %s)""",
                    [
                        (session_id, c.card_no, c.choice, c.weight, c.response_ms)
                        for c in choices
                    ],
                )
        return session_id


_pg_repo: PgRepo | None = None


def get_repo() -> Repo:
    """FastAPI-dependency; testene overstyrer denne med FakeRepo."""
    global _pg_repo
    if _pg_repo is None:
        _pg_repo = PgRepo()
    return _pg_repo


def jsonb(value: dict) -> Jsonb:
    """Helper for seed/tests: wrap a dict for a jsonb parameter."""
    return Jsonb(value)
