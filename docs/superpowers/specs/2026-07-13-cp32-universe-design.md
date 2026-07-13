# CP 3.2 — Universbygger / survivorship (design)

Godkjent av Kristoffer 2026-07-13 (omfang: full S1 med DB-persistering).
Grunnlag: 00_fremgangsmåte CP 3.2, 03 S1, 02 §4 (companies, index_constituents).

## Empirisk grunnlag (validert i dag mot ekte FMP)

- `sp500-constituent`: 503 rader; felt `symbol, name, sector, subSector,
  headQuarter, dateFirstAdded, cik, founded`.
- `historical-sp500-constituent`: 1523 endringer, 1957-03-03 → i dag; felt
  `date` (ikrafttredelse, ISO), `symbol`+`addedSecurity` (lagt til),
  `removedTicker`+`removedSecurity` (fjernet, tomt ved ren addisjon),
  `reason`. 1262/1523 rader har `removedTicker`.
- **Backward-rekonstruksjon validert:** `universe(2016-01-04)` → 504 tickere;
  alle 10 kjente senere-delistede (SNDK, YHOO, MON, TWX, TIF, PCP, ARG, BXLT,
  EMC, LLTC) er til stede; alle 6 post-2016-tillegg er fraværende. 21
  «add-not-present»-anomalier, alle 2022+, påvirker ikke historiske datoer.

## Hvorfor dette er kritisk (helhet → sluttbruker)

universe(D) → Curator plukker 5 → hvis universet kun var overlevere ville
«long alt» alltid vunnet, og spillet lærte bort overoptimisme (motsatt av
tesen). Riktig univers = grunnmuren for at spillet er en ærlig backtest.

## Arkitektur

`backend/pipeline/sp500.py` — rene funksjoner (ingen I/O):

1. **`membership_on(today_symbols: set[str], change_log: list[dict], D: date)
   -> set[str]`** — backward-rekonstruksjon (validert). Start fra dagens sett,
   reverser hver endring med `date > D`: fjern `symbol`, legg tilbake
   `removedTicker`. Korrekthets-*orakelet*.
2. **`build_intervals(today: list[dict], change_log: list[dict])
   -> UniverseBuild`** — **KORRIGERT under implementering:** forward
   event-paring viste seg umulig fordi loggen er *ufullstendig* (338 rader ≤
   2016 er `remove_without_add`/`double_add` — grunnleggermedlemmer fjernet
   uten matchende add, fra før loggens dekning). Endelig algoritme:
   **snapshot-diff forankret på orakelet.** Medlemskap er en trappefunksjon
   som kun endres på endringsdatoer, så `snap[d] = membership_on(d)` beregnes
   inkrementelt bakover fra dagens sett; en forward-diff av påfølgende
   snapshots gir hver tickers disjunkte `[start, end)`-intervaller. Konsistent
   med `membership_on` *by construction* — ingen skjør event-paring, så
   ufullstendig-logg-artefakter kan ikke korrumpere den. Anomali = ticker-
   gjenbruk (ulikt security-navn under samme ticker), logget.
   Returnerer `UniverseBuild(companies, constituents, anomalies)`.
   - `companies`: `[{ticker, name, is_delisted, delisted_date}]` (naturlig
     nøkkel (ticker, name) — navn disambiguerer ticker-gjenbruk).
   - `constituents`: `[{ticker, name, start: date, end: date|None}]`
     (None = infinity/nåværende).
   - `anomalies`: `[{kind, date, ticker, detail}]` — inkonsistente overganger
     logges, krasjer aldri (03 prinsipp 5).

Persistering (`backend/pipeline/persist.py` eller i repo):

3. **`persist_universe(conn, build)`** — i én transaksjon: upsert `companies`
   på (ticker, name) → company_id; `delete from index_constituents where
   index_code='SP500'`; insert alle intervaller som `daterange(start, end)`
   (`end=None` → `daterange(start, null)` = `[start,infinity)`). Idempotent.
4. **`universe(conn, D: date) -> set[int]`** — `select company_id from
   index_constituents where index_code='SP500' and membership @> D`.

Orkestrering: `build_and_persist(client, conn)` henter → bygger → persisterer,
logger anomali-antall.

## Edge cases (normativt)

- **Ren addisjon** (`removedTicker` tom): kun `symbol`-intervall åpnes.
- **Re-entry** (inn→ut→inn): to disjunkte intervaller.
- **Founding member** (1957-add, aldri fjernet, i dagens liste):
  `[1957-03-03, infinity)`.
- **Dobbel-add / remove-uten-add**: anomali, hopp over overgangen.
- **Ticker-gjenbruk innad i indeks** (ulikt `name` for samme ticker):
  detektér + logg som anomali; full company_id-splitt utsettes til det faktisk
  forekommer (schema klart). Praktisk talt ikke-eksisterende historisk.
- **`daterange` halv-åpen** `[start, end)`: `membership @> D` ⇒ D i intervallet;
  en endring på selve D er i kraft på D (start inklusiv), exit på D ekskluderer D.

## Testing

- **Rene enhetstester (syntetiske logger):** enkelt inn/ut; re-entry → 2
  intervaller; additions-only; dobbel-add → anomali; founding member; ticker-
  gjenbruk ulikt navn → anomali; `membership_on` grunnleggende reversering.
- **Survivorship-røyktest (sjekkpunktet):** universe(2016-01-04) inneholder ≥1
  senere-delistet — via *både* `membership_on` og DB.
- **Kryssjekk:** for datoer i {2014,2016,2018,2019} må DB-`universe(D)` (mappet
  til tickere) == `membership_on(D)`. Divergens = intervall-bug.
- **Integrasjon (env-gated FMP + DB):** bygg mot ekte FMP, persistér til hosted
  DB, verifiser antall + røyktest + kryssjekk, rydd (`delete where
  index_code='SP500'` + testselskaper).

## Avgrensninger (YAGNI)

Sektor/industri/iconic/currency = S2 (profile), ikke her. `delisted_date`
grovt fra logg (S4 forfiner fra kursserie-slutt). data_quarantine-tabell = S8;
nå logges anomalier + returneres/telles.
