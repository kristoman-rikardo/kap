# CP 2.2 — Anonym auth + JWT-verifisering (design)

Godkjent av Kristoffer 2026-07-06. Grunnlag: 05_api §3/§6, 02 §9–10,
00_fremgangsmåte CP 2.2. Verifiserte fakta: prosjektet (ref
`ceoilctqdmuorfjeccyx`) signerer access-tokens med **ES256**; JWKS ligger på
`/auth/v1/.well-known/jwks.json`; anonym innlogging er skrudd på via
management-API-et.

## Sjekkpunkt

Appen får et JWT via anonym Supabase-sesjon. FastAPI verifiserer signaturen
mot JWKS: `401` uten/med ugyldig token, `200` med gyldig.

## Backend

- Ny `backend/auth.py`: PyJWT + `PyJWKClient` (JWKS hentes og caches av
  klienten). Verifiser ES256-signatur, `exp`, `aud='authenticated'`; returnér
  `sub` som `user_id` (uuid).
- FastAPI-dependency `CurrentUser` på `/v1/daily` og
  `/v1/batches/{id}/submit`. `/health` forblir åpen.
- `SUPABASE_URL` fra miljø (`.env`). JWKS-URL avledes.
- 401-kropp følger 05 §6-konvolutten: `{"error": {"code": "INVALID_TOKEN", …}}`.
- Testbarhet: testene genererer eget ES256-nøkkelpar og overstyrer
  JWKS-oppslaget — ingen nettverk i test.

## Flutter

- `supabase_flutter`: `Supabase.initialize(url, anonKey)` ved oppstart,
  `signInAnonymously()` hvis ingen persistert sesjon (pakken lagrer sesjonen;
  `user_id`/streak overlever restart, 05 §3).
- Dio-interceptor: `Authorization: Bearer <access_token>` på alle kall;
  ved 401 → forny sesjon og retry én gang, deretter feilskjerm.
- Anon-nøkkel + URL i `lib/config.dart` (offentlig by design).

## Forkastede alternativer

- `python-jose` (svakere vedlikeholdt enn PyJWT).
- Kalle Supabase `/auth/v1/user` per request (nettverkshopp per kall; bryter
  05 §3 «verifiser signaturen selv»).
- Rå REST-auth i Flutter uten `supabase_flutter` (mer kode, null gevinst).

## Verifisering

1. pytest: gyldig token → 200 + riktig `user_id`; utløpt / feil aud / feil
   nøkkel / søppel / manglende → 401.
2. Simulator: appen henter daily med token (200 i serverlogg).
3. `curl` uten token mot `/v1/daily` → 401.
