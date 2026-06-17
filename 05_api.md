# 05_api.md – KAP Spesifikasjon: API-lag (KAPs eget API + ekstern data-API-bruk)

> **Dokumentserie:** `01_scoring` ✓ · `02_datamodell` ✓ · `03_data_pipeline` ✓ · `04_curator` ✓ · **`05_api` (dette)** · `06_frontend_gameloop` · `07_kartoteket` · `08_realtime`
> To deler: **Del A** = KAPs eget API (FastAPI-laget Flutter-klienten kaller). **Del B** = hvordan KAP konsumerer den eksterne data-API-en (FMP `stable`), grunnet i de faktiske docsene (hentet juni 2026). Del B oppdaterer endepunkt-spesifikkene i 03 (som var v3-baserte søkegjetninger).

---

# DEL A — KAPs eget API (FastAPI)

## 1. Designprinsipper

1. **FastAPI er eneste vei til spilldata.** All lesing av `game_batches`/`batch_cards` (service-only, 02 §10) går gjennom FastAPI med service-rollen. Klienten ser aldri tabellene direkte. Dette er anonymiseringsgrensen håndhevet i praksis.
2. **Fasit eksponeres aldri før submit.** `GET`-endepunkter returnerer kun `public_payload` + `card_no`. Navn, ticker, alpha, clue og `decision_date` (kalenderepoken) returneres *kun* i submit-svaret, etter at valgene er mottatt og lagret.
3. **Idempotent og verifiserende submit.** Submit er kilden til `game_sessions`/`decisions`. Den verifiserer batch-tilstand, håndhever ett-forsøk-per-daily (02 §9), og er trygg å re-sende (samme resultat).
4. **Tynt API, tung pipeline.** API-et beregner ikke fasit on-the-fly; den anvender scoringmotoren (01) på frosne kort-truth-verdier (Junior) eller henter batch-tickernes dagsserier (Manager). Ingen FMP-kall i forespørselsløpet.
5. **Versjonert kontrakt.** Alle ruter under `/v1`. Brytende endringer → `/v2`.

## 2. Arkitektur & ansvarsdeling

```
Flutter (Dio)
   │  Supabase JWT (Authorization: Bearer …)
   ▼
FastAPI  /v1/*  ──(service role)──► PostgreSQL/Supabase  (alle domener)
   │                                  ▲
   │                                  │ (RLS «eier egen rad»)
   └─ Supabase Auth (JWKS-verifisering)│
Flutter ───(Supabase-klient, valgfritt for egne data)─┘
```

* **FastAPI (service-rolle):** all spilldata (anonymiserte kort, submit/score/reveal, selskapsprofiler). Bypasser RLS bevisst – derfor *all* anonymisering/strippe-logikk ligger her.
* **Supabase-klient (valgfritt, RLS-beskyttet):** klienten *kan* lese egne `collections`/`game_sessions`/`profiles` direkte via Supabase (RLS «eier egen rad», 02 §10) for å spare FastAPI-ruter. Spilldata kan den aldri.
* **Auth:** Supabase Auth utsteder JWT (også for anonyme brukere). FastAPI verifiserer signaturen mot Supabase JWKS, henter `sub` = `auth.uid()` = `user_id`.

## 3. Autentisering

* **Anonym først (02 §9):** klienten starter en anonym Supabase-sesjon (device-basert) → får JWT. Ingen registrering for å spille Dagens Runde.
* **JWT-verifisering i FastAPI:** valider signatur (Supabase JWKS), `exp`, `aud`; hent `user_id`. Avvist token → `401`.
* **Konto valgfritt:** anonym → permanent konto via Supabase (beholder `user_id`, dermed streak/historikk). `profiles.is_anonymous` speiler dette.
* **Service-rollenøkkel** holdes kun i FastAPI-miljøet (aldri i klient). FMP/OpenAI-nøkler likeså (Del B).

## 4. Endepunkter

Alle krever `Authorization: Bearer <jwt>`. Alle svar er JSON. Tider i UTC ISO-8601.

### 4.1 `GET /v1/daily`
Dagens globale runde (04 §7). Hvis brukeren alt har submittet i dag → returnér resultatet i stedet (felt `already_played: true` + reveal), ellers kortene.

**200 (ikke spilt):**
```json
{
  "batch_id": 9123, "mode": "junior", "is_daily": true,
  "daily_date": "2026-06-17", "horizon_years": 5,
  "intro": { "market_sentiment": "grådig", "rate_picture": "lave, fallende renter", "note": "…" },
  "cards": [
    { "card_no": 1, "payload": {
        "macro": { "rate_level": "lav", "rate_direction": "fallende",
                   "inflation_band": "moderat", "gdp_band": "sunn", "sector_sentiment": "optimistisk" },
        "fundamentals": { "pe": 18.4, "ps": 3.1, "debt_to_equity": 0.6,
                          "gross_margin": 0.41, "operating_margin": 0.22, "net_margin": 0.15, "roic": 0.19 },
        "growth": { "rev_cagr_3y": 0.12, "eps_cagr_3y": 0.09 },
        "cap": "mid", "sector_coarse": "Teknologi" } }
    /* … card_no 2..5 … */
  ]
}
```
**Merk:** ingen `ticker`/`name`/`decision_date` (epoken). `horizon_years` *vises* (spilleren må vite tidshorisonten); makro er bånd-vist (04 §5.7).

### 4.2 `GET /v1/practice`
Vanlig Junior (04 §10). Server velger en sealet øvings-batch brukeren ikke har spilt (dedup mot `game_sessions`). Samme kort-form som §4.1, `is_daily:false`.

### 4.3 `POST /v1/batches/{batch_id}/submit`
Kilden til `game_sessions` + `decisions`; eneste sted fasit eksponeres.

**Request:**
```json
{ "choices": [
    { "card_no": 1, "choice": "long",  "weight": null, "response_ms": 3400 },
    { "card_no": 2, "choice": "short", "weight": null, "response_ms": 2900 }
    /* … alle 5 (Junior). Manager: weight ∈ [0,1] på long/short; resten cash … */
] }
```

**Verifisering:** batch finnes og er `live`; `t1` i fortiden; alle `card_no` tilhører batchen; for daily: ingen tidligere submittet sesjon (ellers `409` + eksisterende resultat); Manager: `Σ weight ≤ 1`. Persistér sesjon+valg, kall scoringmotoren (01), returnér reveal.

**200 (reveal — følger 01 §7-kontrakten):**
```json
{
  "session_id": 55012, "score": -32, "bonus": 0, "hit_rate": 0.5,
  "benchmark": { "R_m": 0.60, "r_m": 0.099, "r_f": 0.016, "alpha_cash": -0.083 },
  "decision_date": "2014-06-02", "horizon_years": 5,
  "cards": [
    { "card_no": 1, "ticker": "…", "name": "…", "choice": "long",
      "R": 1.80, "r": 0.229, "alpha": 0.130, "a": 0.130, "points": 70,
      "clue": "…", "event": null, "company_id": 4412 }
  ],
  "ideal": { /* fasit-portefølje, 01 §8 */ },
  "manager_extra": null
}
```
Idempotens: re-submit på en alt-submittet daily → `409` med samme reveal (ikke ny scoring).

### 4.4 `GET /v1/companies/{company_id}`
Selskapsdata for reveal-siden og Kartoteket (ikke-anonymisert *ved design* – 02 §7). Fra `company_profiles` + (v1.1) historikk fra `financials`/`prices`. Lenkes fra reveal (04 §5, «Utforsk selskapet»).

### 4.5 Egne data (kan gå direkte mot Supabase via RLS)
* `GET /v1/me/stats` – streak, historikk, aggregater (`game_sessions`).
* `POST /v1/collections` / `DELETE /v1/collections/{company_id}` – Kartoteket «Min samling» (02 §9).
* `GET /v1/daily/leaderboard` – dagspersentil fra `game_sessions` for dagens daily (04 §7; cheap, post-MVP-justerbar).

## 5. Anonymiseringsgrensen i praksis

* `GET`-svar inneholder **kun** `public_payload` + `card_no` + batch-meta uten epoke. Truth (`name/ticker/alpha/clue/event`) og `decision_date` returneres **kun** av §4.3 etter submit.
* FastAPI leser `batch_cards` med service-rollen og *strippe-mapper* til payload — truth-kolonnene serialiseres aldri i `GET`-stien (egen Pydantic-modell for kort-visning vs reveal, så et felt ikke kan lekke ved uhell).
* **Caching/CDN:** `GET /v1/daily` (kort, før reveal) er identisk for alle og uforanderlig når `live` → cachebar (dagslang TTL, gjerne CDN). «Already played»-grenen og alle per-bruker-svar caches *ikke*. Reveal er per-bruker og uncachet.

## 6. Feil, statuskoder, rate limiting, versjonering

* **Statuskoder:** `200` ok; `400` valideringsfeil (ugyldig `choice`, `Σweight>1`, ukjent `card_no`); `401` ugyldig/utløpt JWT; `404` ukjent batch/selskap; `409` daily alt spilt / batch ikke `live`; `429` rate limit; `5xx` internt.
* **Feilkropp:** `{ "error": { "code": "DAILY_ALREADY_PLAYED", "message": "…", "detail": {…} } }` (maskinlesbar `code`).
* **Rate limiting (KAPs egen, beskytter backend):** per `user_id`/IP, f.eks. token-bucket; submit strammere enn GET. Egen fra FMP-kvoten (Del B) – ingen FMP-kall i forespørselsløpet uansett.
* **CORS** for app-domenet; **input-validering** via Pydantic; **observability**: strukturert logging per rute (latens, status), aldri logg JWT/nøkler.
* **Versjonering:** `/v1`. Reveal-kontrakten er låst mot 01 §7.

---

# DEL B — Ekstern data-API: FMP (`stable`)

> Grunnet i FMPs faktiske `stable`-docs. **Erstatter endepunkt-spesifikkene i 03 §2/§5** (som brukte v3-stier). Arkitektur, idempotens og kvalitetsport i 03 står; kun stier/felt presiseres her.

## 7. FMP-grunnlag

* **Base:** `https://financialmodelingprep.com/stable/`. (v3-stiene er «legacy»; `stable` er gjeldende.)
* **Auth:** API-nøkkel som header `apikey: <KEY>` *eller* query `?apikey=<KEY>` (`&apikey=` hvis andre parametre finnes). KAP bruker header i pipelinen; nøkkel kun i backend-miljø.
* **Klient:** FMP-klienten i 03 §4.1 består (rate limiter 700/min < 750-taket, backoff på 429/5xx, `402 → PremiumGatedError`). **Oppdater base + paths til `stable`.**
* **Felt-presisjon:** de individuelle docs-sidene er JS-rendret; eksakte feltnavn (casing på `filingDate`/`acceptedDate`, `adjClose` i dividend-adjusted, kolonnenavn i `treasury-rates`) bør bekreftes i API Viewer (`/playground/stable`) eller ved å kjøre en oppdatert `fmp_probe.py` mot `stable`. Feltene under er forventede ut fra dokumentasjon + tidligere verifisering, markert der de må bekreftes.

## 8. Endepunktkart (pipeline-stadie → FMP `stable`-endepunkt)

### 8.1 Univers (survivorship – 03 S1)
| Formål | Endepunkt |
|---|---|
| Nåværende S&P 500 | `GET /stable/sp500-constituent` |
| **Historiske konstituenter** (inn/ut m/ dato) | `GET /stable/historical-sp500-constituent` |
| Delistede selskaper (**Premium**) | `GET /stable/delisted-companies?page=&limit=` |
| Ticker-endringer (mater 02 §4 ticker-gjenbruk) | `GET /stable/symbol-change` |

*Endring vs 03:* stiene er `historical-sp500-constituent` og `delisted-companies` (ikke v3-`historical/sp500_constituent`). `symbol-change` er **ny mulighet** som direkte støtter ticker-gjenbruks-håndteringen.

### 8.2 Entiteter (03 S2)
| Formål | Endepunkt |
|---|---|
| Selskapsprofil (sektor, industri, land, valuta, mktcap) | `GET /stable/profile?symbol=` |
| Sektor-/industri-/land-lister (for `sector_coarse`-mapping + filtre) | `/stable/available-sectors`, `/stable/available-industries`, `/stable/available-countries` |
| Symboluniverser | `/stable/stock-list`, `/stable/financial-statement-symbol-list` |

### 8.3 Finans, point-in-time (03 S3)
| Formål | Endepunkt | Nøkkelfelt (bekreft i Viewer) |
|---|---|---|
| Resultatregnskap | `GET /stable/income-statement?symbol=&period=annual\|quarter&limit=` | `date`, `period`, `filingDate`, `acceptedDate`, `revenue`, `netIncome`, `epsDiluted`, `weightedAverageShsOutDil` |
| Balanse | `GET /stable/balance-sheet-statement?symbol=&period=&limit=` | `totalDebt`, `totalStockholdersEquity` |
| Kontantstrøm | `GET /stable/cash-flow-statement?symbol=&period=&limit=` | `freeCashFlow` |
| Nøkkeltall / ratioer (kryssjekk, ROIC) | `/stable/key-metrics?symbol=`, `/stable/ratios?symbol=` | `roic`, marginer |
| As-reported (rå, om ønsket) | `/stable/income-statement-as-reported?symbol=` m.fl. | — |

**Look-ahead-fiks (03 §5-#5, 02 §6.2):** ankre på `acceptedDate`/`filingDate`; kun rader med `filing_date ≤ decision_date`.
**TTM-felle:** FMP har TTM-endepunkter (`income-statement-ttm`, `key-metrics-ttm`, `ratios-ttm`), men de gir **nåværende** TTM – *ikke* point-in-time per historisk `decision_date`. **Bruk dem kun til Kartoteket (nåtid), aldri til historiske batcher.** Historisk TTM må derives fra kvartalsrader med `filing_date ≤ decision_date` (04 §5.2).

### 8.4 Kurser, totalavkastning (03 S4)
| Formål | Endepunkt |
|---|---|
| **Totalavkastning (splitt+utbytte)** — kortenes/benchmarkens avkastning | `GET /stable/historical-price-eod/dividend-adjusted?symbol=` |
| Rå OHLC/VWAP (debug) | `GET /stable/historical-price-eod/full?symbol=` |
| Ujustert (debug) | `GET /stable/historical-price-eod/non-split-adjusted?symbol=` |

*Viktig presisering vs 03:* det finnes et **dedikert** `dividend-adjusted`-endepunkt — dette er kilden til total return (`adj_close` i 02 §5; bekreft feltnavn). `full` lister OHLC/volum/VWAP og er **ikke** garantert utbyttejustert; ikke bruk den til avkastning. Konsistens-kravet (#4): aksjer *og* SPY hentes fra **samme** `dividend-adjusted`-endepunkt.

### 8.5 Benchmark + market cap
| Formål | Endepunkt |
|---|---|
| **TR-benchmark** (SPY-proxy, låst) | `GET /stable/historical-price-eod/dividend-adjusted?symbol=SPY` |
| Historisk market cap (alt. til `price·shares` for cap-bucket) | `GET /stable/historical-market-capitalization?symbol=` |

*Cap-kategori (04 §5.2):* enten `price(t0)·shares_out` *eller* `historical-market-capitalization` per `decision_date` — sistnevnte er enklere og prisbasert; rank innen universet til relativ bucket uansett.

### 8.6 Hendelser (forbedrer 04 §5.3 event-deteksjon)
| Formål | Endepunkt |
|---|---|
| Oppkjøp (acquired-klassifisering) | `/stable/mergers-acquisitions-search?name=`, `/stable/mergers-acquisitions-latest` |
| SEC-filinger per symbol (konkurs/8-K-mønster) | `/stable/sec-filings-search/symbol?symbol=&from=&to=` |

*Endring vs 04:* event-klassifiseringen (delisted vs acquired) trenger ikke være ren kurs-heuristikk — M&A-endepunktet gir et faktisk oppkjøps-signal. (04 §15-#2 kan oppgraderes fra heuristikk til M&A-oppslag.)

### 8.7 Kartoteket (v1.1)
| Formål | Endepunkt |
|---|---|
| Earnings call-transkript (AI-sammendrag) | `/stable/earning-call-transcript?symbol=&year=&quarter=` |
| Forretningssegmenter | `/stable/revenue-product-segmentation?symbol=`, `/stable/revenue-geographic-segmentation?symbol=` |
| Screen-baserte decks | `/stable/company-screener?…` |
| Historikk-grafer | `dividend-adjusted` + `key-metrics`/`ratios` |

## 9. Økonomidata — FMP erstatter FRED (oppdaterer 03 S5.2/S6)

FMP har egne økonomi-endepunkter, så **FRED blir overflødig** — én leverandør, én nøkkel, én rate-limit, konsistent kilde:

| Formål | Endepunkt | Erstatter |
|---|---|---|
| **Risikofri rente** (3M T-bill, alle løpetider) | `GET /stable/treasury-rates` | FRED `DTB3` |
| Makro (BNP, inflasjon, arbeidsledighet) | `GET /stable/economic-indicators?name=GDP` (m.fl.) | FRED `CPIAUCSL`/`GDPC1` |
| (bonus) Market risk premium | `GET /stable/market-risk-premium` | — |

`treasury-rates`-responsen har kolonner per løpetid (forventet `month3` for 3M; bekreft). Risikofri-konvensjonen (01 §2/§6.6) er uendret. **Anbefaling:** single-vendor (FMP). FRED beholdes kun som fallback hvis FMPs økonomiserier viser seg tynne.

## 10. Tier, kvote, lisens (uendret, men samlet)

* **Premium** forutsatt: 30 års historikk, kvartalstall, delistede kurser, 750 kall/min (begrunnet i tidligere sparring). Backfill av ~1k selskaper × {income, balance, cashflow, key-metrics, dividend-adjusted} ≈ tusenvis av kall → minutter på 700/min, med checkpointing (03 §9).
* **Lisens (uendret flagg):** å *vise* FMP-data til sluttbrukere i en publisert app krever en Data Display/lisensavtale. Greit i dev; ryddes før offentlig lansering (din beslutning fra tidligere: dev-prototype nå).

---

## 11. Grensesnitt mot nabo-specs

* **← 01_scoring:** §4.3 reveal-svaret *er* 01 §7-kontrakten; `manager_extra` fra `game_sessions`.
* **← 02_datamodell:** FastAPI = service-rollen som er eneste leser av spilldata (02 §10); RLS for egne data. Pydantic-skille kort-visning vs reveal håndhever kolonne-stripping.
* **← 03/04:** Del B er den autoritative FMP-endepunktlisten for pipelinen (03) og Curators seal-kall (04). Stable-paths erstatter v3-gjetningene.
* **→ 06_frontend:** Dio-klienten kaller `/v1/*`; modellene (`GameCard`, `GameResult`, `CompanyProfile`, 02 §-frontend) speiler §4-skjemaene.

## 12. Oppdateringer til tidligere specs (samlet)

*Status: **propagert** inn i kildedokumentene (juni 2026). Denne lista er nå en endringslogg, ikke ventende arbeid. Berørte: 03 (gjennomgående), 01 (r_f-kilde), 04 (§5.2/§5.3/§15), Instructions (§4/§5). 02 var kildeagnostisk og uendret.*

1. **03 §2/§5:** alle FMP-stier → `stable` (se §8); `historical-sp500-constituent`, `delisted-companies`, `income-statement` m/ `period`/`limit`.
2. **03 S4:** total return via dedikert `historical-price-eod/dividend-adjusted` (ikke `full`).
3. **03 S5.2/S6 + 01 §2/§9:** FMP `treasury-rates` + `economic-indicators` erstatter FRED (single-vendor; FRED kun fallback).
4. **03 S1 / 02 §4:** `symbol-change`-endepunkt støtter ticker-gjenbruks-håndtering.
5. **04 §5.3/§15-#1:** event-klassifisering bruker `mergers-acquisitions-search` framfor ren kurs-heuristikk.
6. **04 §5.2:** cap-bucket kan bruke `historical-market-capitalization` direkte.
7. **(bonus) 03 S6/S7:** epoke-anonymitet (bånd-visning + epoke-lekkasjesjekk) fra 04 §5.7 ble samtidig lukket i 03.

## 13. Åpne beslutninger

1. **Egne data via Supabase-direkte vs FastAPI** (§4.5): la klienten lese `collections`/`stats` direkte (færre ruter, RLS-beskyttet) eller alt via FastAPI (ett kontaktpunkt)? Forslag: direkte for enkel egendata, FastAPI for alt spillrelatert.
2. **Daily-caching/CDN** (§5): aktivere CDN på `GET /v1/daily` fra start, eller vente til last tilsier det? Forslag: enkel in-app/edge-cache nå, CDN senere.
3. **Feltbekreftelse:** kjøre oppdatert `fmp_probe.py` mot `stable` for å fryse eksakte feltnavn før pipelinen kodes? Anbefalt — jeg kan oppdatere proben til stable-stiene.
4. **Single-vendor økonomi** (§9): låse FMP for risikofri+makro (droppe FRED helt), eller beholde FRED som fallback? Forslag: FMP, FRED som fallback.