# CP 3.3 — Finans + kurser point-in-time (design)

Godkjent av Kristoffer 2026-07-19 (aksepterer 76% delistet-dekning for MVP;
fallback-kilde = backlog). Grunnlag: 00_fremgangsmåte CP 3.3, 03 S3/S4, 02 §6.

## Empirisk grunnlag (validert i dag mot ekte FMP)

- **income-statement** (quarter): felt inkl. `date` (periodeslutt), `period`
  (Q1..Q4), `fiscalYear`, **`filingDate`**, `acceptedDate`, `revenue`,
  `netIncome`, `eps`, `epsDiluted`, `weightedAverageShsOut(Dil)`,
  `grossProfit`, `operatingIncome`, `ebitda`.
- **balance-sheet-statement**: har også `filingDate`; `totalDebt`,
  `totalStockholdersEquity`.
- **key-metrics**: `returnOnInvestedCapital`, `marketCap`, `enterpriseValue`
  — MEN kun `date`/`period`, **ingen filingDate**.
- **ratios**: `grossProfitMargin`, `operatingProfitMargin`, `netProfitMargin`,
  `debtToEquityRatio`, `priceToEarningsRatio` — også kun `date`/`period`.
- **dividend-adjusted**: flat array `symbol,date,adjOpen/High/Low,adjClose,
  volume`. `adjClose` = ekte TR. **Krever from/to.**
- **Delistet-dekning målt:** av 50 samplede delistede i 2016-universet har
  38 (76%) kurser, 24% mangler (YHOO/GMCR/TWC/CA…, typisk eldre oppkjøp).
  2023-delistinger (SIVB/FRC/BBBY) har kurser; enkelte 2016-oppkjøp (SNDK/
  MON/EMC/PCP) mangler.

**Konsekvens for design:** `filing_date` (look-ahead-ankeret) finnes KUN på
statements, så det hentes derfra; ratio/metric-verdier flettes på via
`(fiscalYear, period)`. Manglende delistet-kurser håndteres eksplisitt av
`coverage_ok` (karantene, ikke stille skip) og dekningsraten rapporteres.

## Hvorfor kritisk (helhet → sluttbruker)

Kortet MÅ vise sist *rapporterte* tall per beslutningsdato — Q1-regnskapet var
ikke kjent 1. april, det ble filet uker senere. Viser vi tall ingen hadde,
lærer spillet bort etterpåklokskap. `financials_asof` er look-ahead-vakten
som hele kortets ærlighet hviler på.

## Arkitektur

Lite univers for sjekkpunktet (company_id finnes fra CP 3.2): AAPL, MSFT
(overlevere), SIVB (delistet 2023, HAR kurser → trunkering), SNDK (delistet
2016, MANGLER kurser → coverage_ok skal avvise).

### S3 — `backend/pipeline/financials.py`

- **`merge_period_row(inc, bal, km, rat) -> dict`** (ren): fletter de fire
  kildene for én `(fiscalYear, period)` til ett prisuavhengig radobjekt.
  `filing_date` fra income (fallback balance); `period_date` = income `date`;
  felt: revenue, net_income, eps (epsDiluted), gross/operating/net_margin (fra
  ratios), roic (`returnOnInvestedCapital` fra key-metrics), debt_to_equity
  (fra ratios), `extra={shares_out_dil, market_cap_km}`. **pe/ps/cap_category
  = null** (prisavhengige, 03 prinsipp 3 — regnes av Curator fra price(t0)).
- **`fetch_financials(client, symbol) -> list[dict]`**: henter fire endepunkt
  (period=quarter, limit=40), indekserer key-metrics/ratios på
  `(fiscalYear,period)`, kaller merge_period_row per income-periode.
- **`store_financials(conn, company_id, rows)`**: upsert append-only, nøkkel
  `(company_id, period_date, period_type, filing_date)` DO NOTHING.
- **`financials_asof(conn, company_id, decision_date) -> list[dict]`**: den
  kanoniske 02 §6.2-spørringen (distinct on period_type, siste periode med
  `filing_date <= decision_date`). Look-ahead-vakten.

### S4 — `backend/pipeline/prices.py`

- **`fetch_prices(client, symbol, start, end) -> list[dict]`**:
  `dividend-adjusted` m/ from/to. Tom liste hvis ingen dekning.
- **`store_prices(conn, company_id, rows, delisted_date=None)`**: upsert
  `prices(company_id, date, adj_close)`; dropp rader `date > delisted_date`
  (trunkering per company_id, BBBY-tryggheten).
- **`coverage_ok(conn, company_id, start, end, max_gap_days=10) -> (bool,
  dict)`**: sjekker at serien dekker `[start,end]` uten sammenhengende
  handelsdags-hull > terskel. Selskap uten serie → (False, reason). Detalj-
  dict for rapportering.

### Orkestrering — `backend/pipeline/ingest_universe.py`

`ingest_financials_and_prices(client, conn, company_ids)`: per selskap hent+
lagre finans og kurser (kursvindu fra tidligste periode til delisted_date/i
dag), returnér dekningsrapport `{ingested, price_missing: [...]}`.

## Testing

- **Enhet (rene, fixtures):** merge_period_row (filing fra income, ratio/
  metric-fletting, null pe/ps); trunkeringsfilter; coverage-hull-deteksjon
  som ren funksjon på datolister.
- **Integrasjon (env-gated FMP+DB) — SJEKKPUNKTET:**
  1. ingest AAPL → `financials_asof(company_id, 2016-06-02)` returnerer KUN
     rader med `filing_date <= 2016-06-02`; verifisér eksplisitt at en filing
     datert etter decision_date (for en tidligere periode) ekskluderes.
  2. `coverage_ok(AAPL, vindu)` = True; `coverage_ok(SNDK, 2016 H1)` = False
     (ingen serie).
  3. SIVB-serien trunkeres ved delisted_date (ingen rad etter).
  4. Rydder testdata etter seg.

## Avgrensninger + backlog

- **BACKLOG (notert 2026-07-19):** fallback-kilde for de ~24% delistede uten
  FMP-kurser (annen leverandør eller manuell). For MVP: coverage_ok
  ekskluderer dem, dekningsrate rapporteres.
- pe/ps/cap_category = Curator (seal, price(t0)). Datavask/splittfeil = del av
  coverage-porten grovt nå; full S8-karantenetabell senere. Makro/narrativ =
  S5–S7, egne CP-er.
