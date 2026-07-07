# Hjemskjerm (design)

Bestilling (Kristoffer 2026-07-07): en hjemskjerm først, så tilstander og
persistens er synlige og verifiserbare før Fase 3. Grunnlag: 05 §4.5
(`GET /v1/me/stats` — streak, historikk, aggregater), 06 §12 (daily-flyt +
streak), 06 §3 (screens: home/stats hører til strukturen).

## Formål

Gjøre systemtilstand synlig: har jeg spilt i dag, lagres valgene mine
faktisk, hva er streaken og historikken min — direkte fra databasen.

## Backend

- **Ny ren funksjon** `backend/stats.py: compute_streak(played: set[date],
  today: date) -> int` — Wordle-semantikk: sammenhengende dager som slutter
  i dag (hvis spilt) eller i går (dagens runde ennå ikke spilt); ellers 0.
  TDD med golden-cases.
- **Repo-utvidelse:** `SessionRow(session_id, batch_id, daily_date,
  submitted_at, score, bonus, hit_rate)` + `get_user_sessions(user_id,
  limit=20)` (join game_batches for daily_date, nyeste først). FakeRepo
  speiler.
- **Nytt endepunkt** `GET /v1/me/stats` (auth-krevd):
  `{streak, rounds_played, daily_played_today, today_score, recent:
  [{session_id, daily_date, submitted_at, score, hit_rate}]}`.
  «Spilt i dag» = minst én sesjon på dagens live daily-batch (fri-replay-
  semantikken fra CP 2.3 beholdes; ett-forsøk + already_played er CP 4.2).

## Flutter

- **HomeScreen** blir `home:` i appen; Dagens runde pushes derfra.
  - Stats-stripe: 🔥 streak · runder spilt · dagens score (når spilt).
  - Dagens runde-kort med tre tilstander: ikke spilt (CTA «Spill dagens
    runde»), spilt (score + «allerede spilt i dag»), ingen aktiv runde.
  - «Siste runder»-liste (dato, score, treff) — persistensbeviset.
  - Pull-to-refresh + automatisk refresh når man kommer tilbake fra runden.
- `MeStats`/`SessionSummary` freezed-modeller + `ApiClient.getStats()`.
- Feil-/lastetilstander som på DailyScreen (retry, spinner).

## Testing

1. Backend: streak-golden-tests (tom, kun i dag, kjede, hull, slutter i går);
   stats-endepunktet mot FakeRepo (aggregater + auth-krav).
2. Flutter: widget-tester for HomeScreen (spilt/ikke spilt/ingen runde) med
   fake ApiClient.
3. E2E: simulator — hjem viser tilstand, spill runden, tilbake → teller og
   historikk oppdatert; radene finnes i skyen.

## Avgrensninger (YAGNI)

Ingen øvingsmodus-knapp (/v1/practice finnes ikke ennå), ingen re-visning av
gammel reveal (krever already_played-grenen, CP 4.2), ingen delingskort
(CP 4.3).
