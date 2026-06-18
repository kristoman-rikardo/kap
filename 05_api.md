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
* **Auth:** API-nøkkel som header `apikey: <KEY>` (verifisert på Premium) *eller* query `?apikey=`. KAP bruker header i pipelinen; nøkkel kun i backend-miljø.
* **Klient:** FMP-klienten i 03 §4.1 består (rate limiter 700/min < 750-taket, backoff på 429/5xx, `402 → PremiumGatedError`, `401 → AuthError`). Feilbody-format verifisert (`{"Error Message": …}` / `Restricted Endpoint …`).
* **Felt-presisjon:** alle felt/stier under er **empirisk verifisert mot Premium (juni 2026)** – fullstendige svar og eksempelresponser i `fmp_api_questions.md`.

## 8. Endepunktkart (pipeline-stadie → FMP `stable`-endepunkt)

### 8.1 Univers (survivorship – 03 S1)
| Formål | Endepunkt | Merknad |
|---|---|---|
| Nåværende S&P 500 (503) | `GET /stable/sp500-constituent` | referansepunkt |
| **Survivorship-kilden** (1957→, m/ `removedTicker`+`reason`) | `GET /stable/historical-sp500-constituent` | endringslogg, ikke per-dato-roster |
| Nylig delistede (flagg) | `GET /stable/delisted-companies?page=&limit=` | ⚠️ rullerende ~4-mnd-vindu, *ikke* arkiv (Q11); dedup på `symbol` |
| Nylige ticker-bytter | `GET /stable/symbol-change` | ⚠️ rullerende (~mar 2026, Q14); historisk mapping fra `removedTicker` |

*Korreksjon vs forrige antakelse:* `delisted-companies` og `symbol-change` er **rullerende vinduer**, ikke historiske arkiver. Historisk survivorship og ticker-mapping bygges derfor fra `historical-sp500-constituent.removedTicker` (verifisert tilbake til 1957). MVP er S&P 500-avgrenset, så small-caps som aldri var i indeksen dekkes ikke – akseptabelt.

### 8.2 Entiteter (03 S2)
| Formål | Endepunkt |
|---|---|
| Selskapsprofil (sektor, industri, land, valuta, mktcap) | `GET /stable/profile?symbol=` |
| Sektor-/industri-/land-lister (for `sector_coarse`-mapping + filtre) | `/stable/available-sectors`, `/stable/available-industries`, `/stable/available-countries` |
| Symboluniverser | `/stable/stock-list`, `/stable/financial-statement-symbol-list` |

### 8.3 Finans, point-in-time (03 S3)
| Formål | Endepunkt | Nøkkelfelt (verifisert) |
|---|---|---|
| Resultatregnskap | `GET /stable/income-statement?symbol=&period=annual\|quarter&limit=` | `date`, `period`, `fiscalYear`, `filingDate`, `acceptedDate`, `revenue`, `netIncome`, `eps`, `epsDiluted`, `weightedAverageShsOut(Dil)`, `grossProfit`, `operatingIncome`, `ebitda` |
| Balanse | `GET /stable/balance-sheet-statement?symbol=&period=&limit=` | `totalDebt`, `totalStockholdersEquity` (+ `filingDate`) |
| Kontantstrøm | `GET /stable/cash-flow-statement?symbol=&period=&limit=` | `freeCashFlow`, `operatingCashFlow`, `capitalExpenditure` |
| Nøkkeltall (ROIC) | `/stable/key-metrics?symbol=&period=&limit=` | **`returnOnInvestedCapital`** (ikke `roic`), `marketCap`, `enterpriseValue` — per periode m/ `date` |
| Ratioer (marginer, kryssjekk) | `/stable/ratios?symbol=&period=&limit=` | `grossProfitMargin`, `operatingProfitMargin`, `netProfitMargin`, `priceToEarningsRatio` (periodeslutt-basis – kun referanse) |
| As-reported | `/stable/income-statement-as-reported?symbol=` m.fl. | ikke nødvendig i v1 (Q22) |

**Look-ahead-fiks (02 §6.2):** ankre på `filingDate` (fallback `acceptedDate`); kun rader med `filing_date ≤ decision_date`. Verifisert ~34 dager etter periodeslutt (Q16). Historikk: `limit=40` → 40 år (AAPL 1986→, Q18).
**TTM-felle:** FMP har TTM-endepunkter (`income-statement-ttm`, `key-metrics-ttm`, `ratios-ttm`), men de gir **nåværende** TTM – *ikke* point-in-time per historisk `decision_date`. **Kun Kartoteket (nåtid), aldri historiske batcher.** Historisk TTM derives fra kvartalsrader med `filing_date ≤ decision_date` (04 §5.2).

### 8.4 Kurser, totalavkastning (03 S4)
| Formål | Endepunkt |
|---|---|
| **Totalavkastning (splitt+utbytte)** — kortenes/benchmarkens avkastning | `GET /stable/historical-price-eod/dividend-adjusted?symbol=&from=&to=` |
| Rå OHLC/VWAP (debug, splitt-deteksjon) | `GET /stable/historical-price-eod/full?symbol=` |
| Ujustert (debug) | `GET /stable/historical-price-eod/non-split-adjusted?symbol=` |

*Verifisert (Q23–Q27):* `dividend-adjusted` returnerer en **flat array** med felt `symbol, date, adjOpen, adjHigh, adjLow, adjClose, volume`; `adjClose` er ekte total return (SPY 2005-`adjClose` er 48 % under rå `close`). `…/full` har felt `open/high/low/close/volume/change/changePercent/vwap` og **mangler `adjClose`** → bruk den aldri til avkastning. **`from/to` er obligatorisk** — uten dem returneres kun ~5 år (~1255 rader). Konsistens-kravet (#4): aksjer *og* SPY hentes fra **samme** `dividend-adjusted`-endepunkt.

### 8.5 Benchmark + market cap
| Formål | Endepunkt |
|---|---|
| **TR-benchmark** (SPY-proxy, låst; 1993→, krever `from/to`) | `GET /stable/historical-price-eod/dividend-adjusted?symbol=SPY&from=&to=` |
| Historisk market cap (kun aktive) | `GET /stable/historical-market-capitalization?symbol=&from=&to=` |

*Verifisert:* `^SP500TR` er **ikke tilgjengelig** (402/tom – Q28), så SPY-`adjClose` er eneste TR-kilde. `historical-market-capitalization` (felt `marketCap`, daglig) gir **0 rader for delistede** (Q29). *Cap-kategori (04 §5.2):* bruk `price(t0)·weightedAverageShsOutDil` (virker for alle, inkl. delistede); rank innen universet til relativ bucket.

### 8.6 Hendelser (04 §5.3 event-deteksjon)
*Verifisert (Q37): M&A-endepunktet er **ikke brukbart** for systematisk event-klassifisering* — det støtter kun navnesøk (`?name=`, ikke symbol/datointervall), `targetedSymbol=` gir 400, og det manglet data for 2023-delistingene. SEC-filings-søk per symbol er heller ikke en pålitelig konkurs-detektor.

**Faktisk strategi (04 §5.3):** klassifisér ved seal fra:
1. `historical-sp500-constituent.reason` inneholder «acquisition»/«merger» → `acquired`,
2. sluttkurs nær null på siste handelsdag → `bankruptcy`,
3. ellers → `other`.

`delisting_reason` lagres `null` i v1.

### 8.7 Kartoteket (v1.1)
| Formål | Endepunkt | Status |
|---|---|---|
| Earnings call-transkript | `/stable/earning-call-transcript?symbol=&year=&quarter=` | ❌ **402 – krever Ultimate.** Alternativ: AI-sammendrag fra nøkkeltall+narrativ (S7), ev. dedikert kilde i v1.1 |
| Forretningssegmenter | `/stable/revenue-product-segmentation?symbol=`, `…/revenue-geographic-segmentation?symbol=` | ✅ Premium (felt: `date`,`period`,`data:{segment→beløp}`) |
| Screen-baserte decks | `/stable/company-screener?…` | ✅ filtre: `marketCapMore/LessThan`, `sector`, `industry`, `beta…`, `country`, `exchange`, `isEtf/Fund`, `isActivelyTrading` |
| Historikk-grafer | `dividend-adjusted` + `key-metrics`/`ratios` | ✅ |

*Merk:* en screen som «ROIC > 15 % i 10 år» krever join mot `key-metrics` (`returnOnInvestedCapital`) – screeneren alene dekker markedsfiltre, ikke fundamentale tidsserier.

## 9. Økonomidata — FMP erstatter FRED (oppdaterer 03 S5.2/S6)

FMP har egne økonomi-endepunkter, så **FRED blir overflødig** — én leverandør, én nøkkel, konsistent kilde. Alle verifisert:

| Formål | Endepunkt | Verifisert |
|---|---|---|
| **Risikofri rente** (3M) | `GET /stable/treasury-rates?from=&to=` → kolonne `month3` | **prosent/år** (1,54 = 1,54 %); historikk til **1990** |
| Makro | `GET /stable/economic-indicators?name=&from=&to=` | navn: `realGDP`, `GDP`, `CPI`, `inflationRate` (YoY %), `unemploymentRate`, `federalFunds` |

⚠️ **`from/to` er obligatorisk for begge.** Uten: `treasury-rates` gir kun ~66 siste dager; `economic-indicators` kun 3–11 siste obs. Daglig risikofri faktor: `(1+month3/100)^(1/252)−1` (NB `/100` – enheten er prosent). Renteregime (`rate_level`/`rate_direction`) hentes fra `treasury-rates.month3` (ikke `federalFunds`: daglig + 1990 + markedsbasert – Q34). **Anbefaling:** single-vendor (FMP); FRED kun fallback.

## 10. Tier, kvote, lisens

* **Premium** verifisert: **40 års** statements (AAPL 1986→), kvartalstall m/ filing dates, delistede kurser, **750 kall/min** (token-bucket settes 700). **Ingen bulk-endepunkter** (Q38) → backfill er per-symbol: ~1k selskaper × {income, balance, cashflow, key-metrics, ratios, dividend-adjusted} ≈ 5–6k kall → **~7–10 min** med checkpointing (03 §9).
* **Feilklasser (verifisert):** `401`→`AuthError` (`{"Error Message": …}`), `402`→`PremiumGatedError` (`Restricted Endpoint …`), `429`→backoff (maks 5).
* **Ikke på Premium:** earnings-transkript (`earning-call-transcript` → 402, krever Ultimate – §8.7). `^SP500TR` (402/tom). `historical-market-capitalization` for delistede (0 rader).
* **Lisens (uendret flagg):** å *vise* FMP-data til sluttbrukere i en publisert app krever en Data Display/lisensavtale. Greit i dev; ryddes før lansering (dev-prototype nå).

---

## 11. Grensesnitt mot nabo-specs

* **← 01_scoring:** §4.3 reveal-svaret *er* 01 §7-kontrakten; `manager_extra` fra `game_sessions`.
* **← 02_datamodell:** FastAPI = service-rollen som er eneste leser av spilldata (02 §10); RLS for egne data. Pydantic-skille kort-visning vs reveal håndhever kolonne-stripping.
* **← 03/04:** Del B er den autoritative FMP-endepunktlisten for pipelinen (03) og Curators seal-kall (04). Stable-paths erstatter v3-gjetningene.
* **→ 06_frontend:** Dio-klienten kaller `/v1/*`; modellene (`GameCard`, `GameResult`, `CompanyProfile`, 02 §-frontend) speiler §4-skjemaene.

## 12. Oppdateringer til tidligere specs (samlet)

*Status: **propagert** inn i kildedokumentene. To runder: (A) stable-migrering + FRED→FMP (juni 2026), (B) empirisk verifisering mot Premium som **korrigerte** flere antakelser. Berørte: 03 (gjennomgående), 01 (§4, §6.6), 02 (§3.3, §4, §14), 04 (§5.2/§5.3/§15), Instructions (§4/§5).*

**Runde A (docs/stable):**
1. Alle FMP-stier → `stable`; total return via `dividend-adjusted` (ikke `full`); `treasury-rates`+`economic-indicators` erstatter FRED; epoke-anonymitet lukket i 03 S6/S7.

**Runde B (empirisk – korreksjoner):**
2. ⚠️ **`delisted-companies` er rullerende ~4-mnd-vindu, ikke arkiv** → survivorship-kilden er `historical-sp500-constituent.removedTicker` (1957→). Samme for `symbol-change` (rullerende). *(03 S1, 02 §4, Instructions §4)*
3. ⚠️ **`dividend-adjusted`/`treasury-rates`/`economic-indicators` krever `from/to`** (ellers kun ~5 år / ~66 dager / 3–11 obs). *(03 S4/S5/S6)*
4. ⚠️ **M&A-endepunktet er ubrukbart** for event-klassifisering (kun navnesøk) → logg-`reason` + sluttkurs-heuristikk. **Reverterer runde-A-antakelsen.** *(03 S1/§8, 04 §5.3/§15)*
5. ⚠️ **Restatements ikke tilgjengelig** (én versjon/periode) → bitemporalitet er fremtidssikring. *(02 §3.3/§14, 03)*
6. ⚠️ **ROIC-feltet heter `returnOnInvestedCapital`** (ikke `roic`); marginer i `ratios` (ikke income). `treasury-rates.month3` er i **prosent** (faktor `/100`). *(03 S3/S5.2, 01 §6.6)*
7. ❌ **Ingen bulk** → per-symbol backfill (~7 min). ❌ **transcripts krever Ultimate.** ❌ **`^SP500TR` utilgjengelig** → SPY bekreftet eneste TR-kilde. ✅ Survivorship/delisted-kurser/40-års-historikk/SPY-1993/header-auth bekreftet.

## 13. Åpne beslutninger

1. **Egne data via Supabase-direkte vs FastAPI** (§4.5): la klienten lese `collections`/`stats` direkte (færre ruter, RLS-beskyttet) eller alt via FastAPI (ett kontaktpunkt)? Forslag: direkte for enkel egendata, FastAPI for alt spillrelatert.
2. **Daily-caching/CDN** (§5): aktivere CDN på `GET /v1/daily` fra start, eller vente til last tilsier det? Forslag: enkel in-app/edge-cache nå, CDN senere.
3. ~~**Feltbekreftelse:**~~ **LØST** – alle felt empirisk verifisert mot Premium (juni 2026, `fmp_api_questions.md`). Bulk avklart: finnes ikke på Premium → per-symbol backfill (§10).
4. **Single-vendor økonomi** (§9): låse FMP for risikofri+makro (droppe FRED helt), eller beholde FRED som fallback? Forslag: FMP, FRED som fallback.