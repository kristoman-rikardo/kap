# CP 2.3 — Loopen mot databasen (design)

Grunnlag: 00_fremgangsmåte CP 2.3, 02 §8/§9/§15, 05 §4. Verifiserte fakta:
session-pooleren (`aws-1-eu-north-1.pooler.supabase.com:5432`, IPv4) er nåbar
og autentiserer som `postgres` (tabelleier → service-tilgang, bypasser RLS);
`SUPABASE_DB_URL` ligger i `.env`.

## Sjekkpunkt

Loopen går mot databasen: `GET /v1/daily` leser dagens sealed/live batch fra
`game_batches`/`batch_cards`, submit scorer fra frosne truth-rader og logger
`game_sessions` + `decisions`. Egne valg kan spørres opp etterpå. RLS testet:
en bruker ser kun egne rader, og `batch_cards` er utilgjengelig for klienter.

## Arkitektur

- **DB-tilgang:** psycopg3 (sync) + connection pool i `backend/db.py`.
  Valgt over supabase-py/PostgREST fordi submit trenger transaksjon
  (session + 5 decisions atomisk) og spec-en definerer FastAPI som
  service-rollen mot Postgres (05 §2). Pooler i session-mode (IPv4 —
  direktehosten er IPv6-only).
- **Repo-grensesnitt:** `backend/repo.py` med `Repo`-protokoll:
  `get_live_daily()`, `get_batch_meta(id)`, `get_batch_truth(id)`,
  `record_session(...)`. `PgRepo` implementerer mot Postgres; testene bruker
  en `FakeRepo` bygget på dagens fixture (dependency_overrides) — alle
  eksisterende API-tester består uendret i semantikk.
- **Seed (02 §15):** idempotent `backend/seed.py` (upsert): 7 selskaper — de
  5 golden fixture-selskapene + ett delistet (BBRG, bankruptcy) og ett
  oppkjøpt (ACQD) for universets del — og én sealed→live daily-batch der
  `batch_cards` fryser public_payload (fra fake_data) + truth (navn, alpha,
  ret_cum/ret_ann, clue) beregnet av scoringmotoren. Benchmark fryses på
  batchen (`r_m_cum/r_m/r_f_cum/r_f/alpha_cash`, 02 §8).
- **Skjema-avvik:** API-kontrakten (05 §4.1) har batch-nivå `intro`, som
  02-skjemaet mangler → ny migrasjon `alter table game_batches add column
  intro jsonb`. Dokumentert som spec-gap.
- **Daily-semantikk i CP 2.3:** sesjoner logges med `is_daily=false`
  (øvings-semantikk, fri replay i dev). Ett-forsøk-håndhevelsen +
  `already_played`-grenen er CP 4.2 og aktiveres der. `session_id` i
  reveal kommer nå fra DB.

## Testing

1. **Unit (uendret hastighet):** endepunkter mot `FakeRepo`; nye tester for
   at submit registrerer session + decisions og 404 på ukjent/ikke-live batch.
2. **Integrasjon (env-gated, kjøres lokalt):** mot den hostede databasen —
   seed, les daily, submit golden round (score ≈ −31.58), les decisions
   tilbake som service; rydder etter seg.
3. **RLS-bevis:** to anonyme brukere (auth REST): bruker A ser egne
   `game_sessions`/`decisions` via PostgREST, ser ikke Bs, og `batch_cards`
   gir tom respons for begge.
4. **E2E:** appen på simulatoren spiller runden mot DB-batchen; skjermbevis +
   decisions-rader i skyen.
