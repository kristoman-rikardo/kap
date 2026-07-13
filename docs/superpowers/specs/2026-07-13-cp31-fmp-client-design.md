# CP 3.1 — FMP-klient (design)

Grunnlag: 03 §4.1, 05 Del B, 00_fremgangsmåte CP 3.1. Empirisk verifisert i
dag mot Premium-nøkkelen: income-statement→200, earning-call-transcript→402,
feil nøkkel→401. Nøkkel i `.env` som `FMP_API_KEY` (gitignored).

## Sjekkpunkt

Et kall henter AAPL income-statement (200 + rader m/ filingDate). En bevisst
gated forespørsel (earning-call-transcript, krever Ultimate) gir riktig
`PremiumGatedError` — ikke stille skip.

## Arkitektur

Ett tynt lag, ett ansvar: hente robust innenfor kvote (03 prinsipp 7).
`backend/fmp.py`:

- **Feilhierarki:** `FMPError` base; `AuthError` (401/403), `PremiumGatedError`
  (402, bærer `path`), `RateLimitError` (429 etter maks retry), `FMPServerError`
  (5xx etter maks retry).
- **`FMPClient.get(path, **params) -> list | dict`:**
  - Token-bucket rate limiter (700/min < 750-taket). Capacity + refill styrt
    av injiserbar `monotonic`/`sleep` → testbar uten ekte tid.
  - Retry m/ eksponentiell backoff på 429 og 5xx (maks 5 forsøk).
  - 402 → `PremiumGatedError(path)` umiddelbart (03 §4.1: høylytt, ikke skip —
    et stille skip gjeninnfører survivorship-bias snikende).
  - 401/403 → `AuthError`.
  - Auth via HTTP-header `apikey:` (verifisert). Nøkkel kun i backend-miljø.
- **Injiserbar `session`** (`requests.Session`-lignende: `.get(url, params,
  headers, timeout)`), `sleep`, `monotonic` — all nettverk/tid er sømmer, så
  enhetstestene er hermetiske.
- Lettvekts strukturert logg per kall (path, status, ms). DB-`ingestion_runs`
  (03 §4.3) kommer med senere stadier; ikke nødvendig for klienten.

`requests` er allerede en avhengighet.

## Forkastede alternativer

- httpx/async: pipelinen er en sekvensiell batch-jobb; sync + requests er
  enklere og nok. Async gir ingen gevinst for per-symbol backfill.
- Ekte `time.sleep` i rate-limiter uten søm: ville gjort testene trege/flaky.

## Testing

1. **Enhet (hermetisk, fake session + fake klokke):** 200→data; 402→
   PremiumGatedError m/ path; 401→AuthError; 429 så 200→retry og suksess;
   429×maks→RateLimitError; 5xx→FMPServerError; rate-limiter slipper N kall
   innen budsjett og blokkerer/sover på tomt bøtte (verifisert via fake
   monotonic, ingen ekte sleep); `apikey`-header settes.
2. **Integrasjon (env-gated på FMP_API_KEY) — SJEKKPUNKTET:** ekte AAPL
   income-statement returnerer rader m/ `filingDate`; earning-call-transcript
   reiser `PremiumGatedError`.
