"""Seed the fixture universe (CP 2.3, 02 §15) into the hosted DB.

Idempotent: re-running updates in place. Seeds 7 companies — the five golden
fixture companies (01 §3.3) plus one bankrupt and one acquired (universe-level
survivorship properties) — and one sealed→live daily batch whose cards freeze
public_payload + truth exactly as the Curator will at seal (02 §8).

Run:  uv run python -m backend.seed [--daily-date YYYY-MM-DD]
"""

from __future__ import annotations

import argparse
import datetime as dt

from psycopg.types.json import Jsonb

from backend.db import pool
from backend.fake_data import _CARDS, _HORIZON_YEARS, _R_F, _R_M, _TRUTH
from backend.fake_data import fake_daily_batch
from backend.scoring import annualize

DECISION_DATE = dt.date(2014, 6, 2)
SEED = 20140602

# (ticker, name, sector_coarse, is_delisted, delisted_date, reason)
_EXTRA_COMPANIES = [
    ("BBRG", "Bramble Retail Group", "Forbruksvarer", True,
     dt.date(2016, 3, 18), "bankruptcy"),
    ("ACQD", "Acquired Diagnostics", "Helse", True,
     dt.date(2018, 9, 28), "acquired"),
]


def _upsert_company(cur, ticker: str, name: str, sector_coarse: str,
                    is_delisted: bool = False, delisted_date=None,
                    reason: str | None = None) -> int:
    row = cur.execute(
        "select id from companies where ticker = %s and name = %s",
        (ticker, name),
    ).fetchone()
    if row:
        return row[0]
    return cur.execute(
        """insert into companies
             (ticker, name, sector_coarse, is_delisted, delisted_date,
              delisting_reason)
           values (%s, %s, %s, %s, %s, %s) returning id""",
        (ticker, name, sector_coarse, is_delisted, delisted_date, reason),
    ).fetchone()[0]


def seed(daily_date: dt.date) -> None:
    batch = fake_daily_batch()
    r_m = annualize(_R_M, _HORIZON_YEARS)
    r_f = annualize(_R_F, _HORIZON_YEARS)
    payload_by_no = {c.card_no: c.payload for c in _CARDS}

    with pool().connection() as conn, conn.cursor() as cur:
        company_ids: dict[int, int] = {}
        for card_no, ticker, name, _fake_id, _R, _clue in _TRUTH:
            payload = payload_by_no[card_no]
            company_ids[card_no] = _upsert_company(
                cur, ticker, name, payload.sector_coarse
            )
        for args in _EXTRA_COMPANIES:
            _upsert_company(cur, *args)

        existing = cur.execute(
            "select id from game_batches where is_daily and daily_date = %s",
            (daily_date,),
        ).fetchone()
        batch_args = (
            "junior", DECISION_DATE, _HORIZON_YEARS, SEED, daily_date,
            Jsonb(batch.intro.model_dump()),
            _R_M, r_m, _R_F, r_f, r_f - r_m,
        )
        if existing:
            batch_id = existing[0]
            cur.execute(
                """update game_batches set
                     mode=%s, decision_date=%s, horizon_years=%s, seed=%s,
                     daily_date=%s, intro=%s, r_m_cum=%s, r_m=%s, r_f_cum=%s,
                     r_f=%s, alpha_cash=%s, status='live', sealed_at=now()
                   where id = %s""",
                (*batch_args, batch_id),
            )
        else:
            batch_id = cur.execute(
                """insert into game_batches
                     (mode, decision_date, horizon_years, seed, is_daily,
                      daily_date, intro, r_m_cum, r_m, r_f_cum, r_f,
                      alpha_cash, status, sealed_at)
                   values (%s, %s, %s, %s, true, %s, %s, %s, %s, %s, %s, %s,
                           'live', now())
                   returning id""",
                batch_args,
            ).fetchone()[0]

        for card_no, ticker, name, _fake_id, R, clue in _TRUTH:
            payload = payload_by_no[card_no]
            ret_ann = annualize(R, _HORIZON_YEARS)
            cur.execute(
                """insert into batch_cards
                     (batch_id, card_no, company_id, public_payload,
                      f_pe, f_debt_to_equity, f_rev_cagr, f_sector, f_cap,
                      name, alpha, ret_cum, ret_ann, event, clue)
                   values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                           %s, 'none', %s)
                   on conflict (batch_id, card_no) do update set
                     company_id=excluded.company_id,
                     public_payload=excluded.public_payload,
                     f_pe=excluded.f_pe,
                     f_debt_to_equity=excluded.f_debt_to_equity,
                     f_rev_cagr=excluded.f_rev_cagr,
                     f_sector=excluded.f_sector, f_cap=excluded.f_cap,
                     name=excluded.name, alpha=excluded.alpha,
                     ret_cum=excluded.ret_cum, ret_ann=excluded.ret_ann,
                     event=excluded.event, clue=excluded.clue""",
                (
                    batch_id, card_no, company_ids[card_no],
                    Jsonb(payload.model_dump()),
                    payload.fundamentals.pe,
                    payload.fundamentals.debt_to_equity,
                    payload.growth.rev_cagr_3y,
                    payload.sector_coarse, payload.cap,
                    name, ret_ann - r_m, R, ret_ann, clue,
                ),
            )

        n_companies = cur.execute("select count(*) from companies").fetchone()[0]
        n_cards = cur.execute(
            "select count(*) from batch_cards where batch_id = %s", (batch_id,)
        ).fetchone()[0]
    print(
        f"Seed OK: batch {batch_id} live (daily_date={daily_date}), "
        f"{n_cards} kort, {n_companies} selskaper totalt."
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--daily-date",
        type=dt.date.fromisoformat,
        default=dt.date.today(),
    )
    try:
        seed(parser.parse_args().daily_date)
    finally:
        pool().close()  # ellers henger poolens arbeidstråder ved exit
