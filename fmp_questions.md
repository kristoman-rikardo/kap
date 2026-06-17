# FMP API – åpne spørsmål og verifiserte svar (for KAP-pipelinen)

> **Status:** Alle spørsmål besvart empirisk mot Premium-nøkkel, juni 2026.
> **Metode:** Python-probe (`fmp_probe.py` + ad-hoc kall) mot `https://financialmodelingprep.com/stable/`.
> Svar merket ✅ (bekreftet), ⚠️ (viktig forbehold), ❌ (ikke tilgjengelig/problem).

---

## §0 Global mekanikk

### Q1 🔴 Rate limit
✅ **750 req/min på Premium** (per FMP docs). Ingen 429 observert under testing. 5 raske kall
gjennomsnitt ~733ms — ingen throttling. FMP dokumenterer ikke et daglig tak for Premium; intet
daglig tak er observert i prøvekjøringer.

**Implikasjon for pipeline:** Klientens token-bucket settes til 700/min (10 % margin). Backfill av
~1 000 selskaper × 5 endepunkter ≈ 5 000 kall → under 10 minutters kjøretid.

---

### Q2 🔴 Respons ved overskridelse / feil plan
```
HTTP 401 – Ugyldig nøkkel:
  {"Error Message": "Invalid API KEY. Feel free to create a Free API Key or visit ..."}

HTTP 402 – Endepunkt ikke på din plan:
  "Restricted Endpoint: This endpoint is not available under your current subscription
   please visit our subscription page to upgrade your plan at https://financialmodelingprep.com/"

HTTP 429 – Rate limit (ikke observert, men forventet format fra docs):
  {"Error Message": "Limit Reach. Please upgrade your plan..."}
```

**Implikasjon for pipeline:** Tre distinkte feilklasser:
- `401` → `AuthError` (feil nøkkel / utgått)
- `402` → `PremiumGatedError(path)` — høylytt feil, IKKE stille skip
- `429` → retry med eksponentiell backoff (maks 5 forsøk)

---

### Q3 🟡 Datoformat & tidssone
✅ **Datoer:** `YYYY-MM-DD` (alle felt med dato).
✅ **Tidsstempler** (`acceptedDate`): `YYYY-MM-DD HH:MM:SS` uten eksplisitt tidssone-suffiks —
men basert på SEC-innlevering tolkes de som **US Eastern Time** (ET/EST). Eksempel fra AAPL FY2025:
```
date:         2025-09-27     (periodeslutt)
filingDate:   2025-10-31     (kun dato)
acceptedDate: 2025-10-31 06:01:26  (tidsstempel — SEC accepterer typisk kl. 06:xx ET)
```
**Implikasjon for pipeline:** Bruk `filingDate` som look-ahead-anker (dato-granularitet er nok).
`acceptedDate` er mer presis men krever tidssone-omregning hvis man vil ha time-of-day presisjon
(ikke nødvendig for daglig granularitet i KAP).

---

### Q4 🟡 Sortering
✅ **Nyeste-først** på alle historiske arrays:
- `income-statement`: `['2025-09-27', '2024-09-28', '2023-09-30']`
- `historical-price-eod/*`: `['2026-06-17', '2026-06-16', '2026-06-15', ...]`

**Implikasjon:** Point-in-time-spørringen henter `d[0]` = siste kjente rad. Iterasjon fra eldst
til nyest krever reversering.

---

### Q5 🟡 Paginering
✅ **`page` + `limit`** fungerer på `delisted-companies` (og andre lister).
- Siste side = tom array `[]` (ikke `"message": "no data"` eller noe annet).
- Overlapp observert mellom page=0 og page=1 (`MMLG` dukket opp to ganger) — **bruk deduplicering
  på symbol ved innhenting**.
- Maks `limit` per kall: ikke dokumentert av FMP; 1 000 er testet og returnerte 100 rader (indikerer
  at 100 kan være faktisk maks, eller at det bare var 100 resultater). Bruk 100 som trygg øvre grense.

---

### Q6 🟡 Auth via header
✅ **`apikey: <nøkkel>` som HTTP-header virker på Premium** (status 200, korrekt data).

```python
headers = {"apikey": KEY}
requests.get(url, params=other_params, headers=headers)
```

**Anbefaling:** Send nøkkel i header (ikke query param) i produksjon — hindrer at nøkkelen
logges i server-access-logs og URL-historikk.

---

## §1 Univers & survivorship

### Q7 🔴 Historiske S&P 500-konstituenter — feltstruktur
✅ Endepunkt: `GET /stable/historical-sp500-constituent`

**Eksempel (3 rader):**
```json
[
  {
    "dateAdded": "June 01, 2026",
    "addedSecurity": "FedEx Freight Holding Company, Inc.",
    "removedTicker": "EPAM",
    "removedSecurity": "EPAM Systems, Inc.",
    "date": "2026-06-01",
    "symbol": "FDXF",
    "reason": "Market capitalization change."
  },
  {
    "dateAdded": "May 07, 2026",
    "addedSecurity": "Veeva Systems Inc.",
    "removedTicker": "CTRA",
    "removedSecurity": "Coterra Energy Inc.",
    "date": "2026-05-07",
    "symbol": "VEEV",
    "reason": "Coterra Energy was removed due to its acquisition by Devon Energy."
  }
]
```

**Feltbeskrivelse:**
| Felt | Innhold |
|------|---------|
| `date` | Datoen endringen trådte i kraft (`YYYY-MM-DD`) — **dette er membership-datoen** |
| `symbol` | Tickeren som ble *lagt til* |
| `addedSecurity` | Fullt navn på selskapet som kom inn |
| `removedTicker` | Tickeren som ble *fjernet* (null/tom hvis bare tillegg) |
| `removedSecurity` | Fullt navn på selskapet som gikk ut |
| `reason` | Fritekst — gir kontekst (fusjon, markedsverdi, osv.) |
| `dateAdded` | Menneskevennlig datostreng (redundant med `date`) |

⚠️ **Viktig semantikk:** Hver rad beskriver én bytte-hendelse (ett inn, ett ut). Det er *ikke* en
komplett radikalliste per dato — det er en logg av endringer. Rekonstruksjon av universet per dato D
krever: start med nåværende liste → «spol tilbake» ved å undone alle endringer med `date > D`.

---

### Q8 🟡 Historikkdybde for konstituent-historikk
✅ **1 520 endringer totalt. Tidligste dato: 1957-03-04.** Dekker hele S&P 500-historikken.

---

### Q9 🟡 Nåværende S&P 500-konstituenter
✅ `GET /stable/sp500-constituent` → 503 selskaper.

**Feltstruktur:**
```json
{
  "symbol": "FDXF",
  "name": "FedEx Freight Holding Company, Inc.",
  "sector": "Industrials",
  "subSector": "Integrated Freight & Logistics",
  "headQuarter": "Harrison, Arkansas",
  "dateFirstAdded": "2026-06-01",
  "cik": "0002082247",
  "founded": "1971-01-01"
}
```

---

### Q10 🔴 Delistede selskaper — feltstruktur
✅ `GET /stable/delisted-companies?page=0&limit=100`

**Feltstruktur:**
```json
{
  "symbol": "SKBL",
  "companyName": "Skyline Builders Group Holding Limited",
  "exchange": "NASDAQ",
  "ipoDate": "2025-01-23",
  "delistedDate": "2026-06-17"
}
```
Felt: `symbol`, `companyName`, `exchange`, `ipoDate`, `delistedDate`. Ingen `delistingReason`.

---

### Q11 🟡 Delistede — omfang og historikk
⚠️ **KRITISK FUNN — endepunktet er en rullerende liste, IKKE et historisk arkiv.**

Testing med `page=0–100, limit=5` viser at eldste `delistedDate` i systemet er ~**februar 2026**
(side 100 gav datoer 2026-02-10). Dette betyr at `delisted-companies` kun dekker delistinger fra
de siste ~4 månedene, ikke historiske perioder (2015–2020) vi trenger for backtesting.

**Løsningen er `historical-sp500-constituent`:** `removedTicker`-feltet gir tickeren på alle
selskaper som *forlot* S&P 500 siden 1957, inkludert de som ble delistet. Dette er den reelle
survivorship-kilden for S&P 500-universet.

Selskaper som aldri var i S&P 500 men som ble delistet (f.eks. small caps) dekkes *ikke* av
denne kombinasjonen — men KAP MVP er avgrenset til S&P 500-universet, så dette er akseptabelt.

---

### Q12 🔴 ⭐ KURSHISTORIKK FOR DELISTEDE — SURVIVORSHIP-LINCHPINNEN
✅ **Premium leverer kurshistorikk for delistede selskaper.** Alle tre testet:

| Ticker | Status | Rader | Spenn | adjClose? |
|--------|--------|-------|-------|-----------|
| SIVB | ✅ | 434 | 2021-06-18 → 2023-03-09 | Ja |
| FRC | ✅ | 484 | 2021-06-18 → 2023-05-23 | Ja |
| BBBY* | ⚠️ | 1255 | 2021-06-18 → 2026-06-17 | Ja |

*BBBY viser data frem til i dag — tickeren er sannsynligvis gjenbrukt etter opprinnelig delisting
(Bed Bath & Beyond konkurs 2023). **Dette er symbol-gjenbruk-problemet (02 §4).** Kursserien
for BBBY post-2023 tilhører et annet selskap. Pipeline må håndtere dette via `company_id`-mapping
og `delisted_date`-truncering.

**Feltstruktur fra `dividend-adjusted`:**
```json
{
  "symbol": "SIVB",
  "date": "2023-03-09",
  "adjOpen": 176.55,
  "adjHigh": 177.75,
  "adjLow": 100.0,
  "adjClose": 106.04,
  "volume": 38746481
}
```
Felt: `symbol`, `date`, `adjOpen`, `adjHigh`, `adjLow`, `adjClose`, `volume`.

⚠️ **Viktig begrensning på `from/to`:** Uten `from/to` returneres kun ~1255 rader (≈5 år
med daglige data). Med `from/to` er full historikk tilgjengelig — se Q24.

---

### Q13 🟡 Regnskap for delistede
✅ `GET /stable/income-statement?symbol=SIVB&period=annual&limit=5` returnerer 5 rader med
korrekt `filingDate` og `acceptedDate`. Alle regnskapsfelt er befolket som for aktive selskaper.
Look-ahead-vakten virker også for delistede.

---

### Q14 🟡 Ticker-endringer (symbol-change)
⚠️ **Endepunktet har begrenset historikk** — med paginering (page=0–100) er eldste dato
~mars 2026. Ikke et historisk arkiv.

**Feltstruktur:**
```json
{
  "date": "2026-06-17",
  "companyName": "Skyline Builders Group Holding Limited Class A Ordinary Shares",
  "oldSymbol": "SKBL",
  "newSymbol": "KAZR"
}
```

**Konsekvens for pipeline:** Symbol-gjenbruk må håndteres via `company_id`-mapping kombinert med
`is_delisted + delisted_date` på `companies`-tabellen (02 §4). `symbol-change` kan brukes til
proaktiv mapping av *nylige* navneendringer, men historiske ticker-mappinger må bygges fra
`historical-sp500-constituent.removedTicker`-loggen.

---

## §2 Finans — point-in-time

### Q15 🔴 Resultatregnskap — komplett feltliste
✅ `GET /stable/income-statement?symbol=AAPL&period=annual&limit=2`

**Alle felt bekreftet (eksakt casing):**

| Vår kolonne | FMP-felt | Eksempelverdi (FY2025) |
|-------------|----------|----------------------|
| `period_date` | `date` | `"2025-09-27"` |
| `period_type` | `period` | `"FY"` (annual) / `"Q1"`–`"Q4"` (quarter) |
| — | `fiscalYear` | `"2025"` |
| `filing_date` | `filingDate` | `"2025-10-31"` |
| — | `acceptedDate` | `"2025-10-31 06:01:26"` |
| `reported_currency` | `reportedCurrency` | `"USD"` |
| — | `cik` | `"0000320193"` |
| `revenue` | `revenue` | `416161000000` |
| `net_income` | `netIncome` | `112010000000` |
| `eps` | `eps` | `7.49` (basic) |
| `eps_diluted` | `epsDiluted` | `7.46` |
| `shares_out` | `weightedAverageShsOut` | `14948500000` |
| `shares_out_dil` | `weightedAverageShsOutDil` | `15004697000` |
| `gross_profit` | `grossProfit` | `195201000000` |
| `operating_income` | `operatingIncome` | `133050000000` |
| `ebitda` | `ebitda` | `144427000000` |
| `r_and_d` | `researchAndDevelopmentExpenses` | `34550000000` |
| `sga` | `sellingGeneralAndAdministrativeExpenses` | `27601000000` |
| — | `grossProfitRatio` | *ikke i income-statement* (se `ratios`) |

⚠️ **`grossProfitRatio` og andre marginer finnes IKKE direkte i income-statement** — de er i
`ratios`-endepunktet (se Q20). Pipeline beregner marginene selv fra `grossProfit/revenue` etc.

---

### Q16 🔴 Look-ahead-ankeret — bekreftet
✅ **`filingDate` og `acceptedDate` er konsekvent ETTER `date` (periodeslutt).**

Eksempel (AAPL FY2025):
```
date (periodeslutt): 2025-09-27
filingDate:          2025-10-31   → 34 dager etter periodeslutt
acceptedDate:        2025-10-31 06:01:26
```

Look-ahead-vakten virker som designet. Kortet vises bare etter `filingDate`, og avkastningen
måles fra første handelsdag etter `filingDate`.

**Valgt anker (03_pipeline §3, låst beslutning):** `filingDate` (dato-granularitet er tilstrekkelig
for daglig henting; `acceptedDate` brukes som fallback hvis `filingDate` er null).

---

### Q17 🔴 Kvartalstall — virker og har filing dates
✅ `GET /stable/income-statement?symbol=AAPL&period=quarter&limit=2` returnerer korrekte data.
`filingDate` og `acceptedDate` er til stede i kvartalsrader — identisk struktur som årsrader.

Eksempel:
```
date: 2026-03-28  (Q2 FY2026)
filingDate: 2026-05-01   → 34 dager etter kvartalsslutt
acceptedDate: 2026-05-01 10:01:00
```

---

### Q18 🔴 Historikkdybde — 40 år tilgjengelig
✅ `GET /stable/income-statement?symbol=AAPL&period=annual&limit=40` returnerer **40 rader**,
spenn **1986–2025**. Ryggraden for Premium-løftet om «30 år» holder — AAPL har data tilbake
til 1986 (børsnotering 1980, men FMP-dekning starter ~1986).

**Implikasjon:** Batch-perioder tilbake til ~1990 er realistiske for store selskaper.
Mindre/nyere selskaper har naturlig kortere historikk.

---

### Q19 🟡 Balanse og kontantstrøm — feltbekreftelse
✅ Alle felt bekreftet med eksakt casing:

**Balance sheet:**
- `totalDebt` → `112377000000` (= kortfristet + langsiktig gjeld)
- `totalStockholdersEquity` → `73733000000`
- `totalAssets`, `totalLiabilities`, `netDebt` til stede
- Har også `filingDate` og `acceptedDate` (samme timing som income statement)

**Cash flow:**
- `freeCashFlow` → `98767000000`
- `operatingCashFlow` → `111482000000`
- `capitalExpenditure` → `-12715000000`
- `netIncome`, `depreciationAndAmortization` til stede

**Debt/Equity beregning:** Bruk `totalDebt / totalStockholdersEquity` fra balance sheet.
FMP leverer `totalDebt` direkte (sum av kort- og langsiktig).

---

### Q20 🔴 Key-metrics og ratios — historiske, per periode
✅ **Begge er historiske** (ikke bare nåtidsverdier). De har `date`, `period`, `fiscalYear`.

**key-metrics — relevante felt bekreftet:**
```json
{
  "symbol": "AAPL",
  "date": "2025-09-27",
  "fiscalYear": "2025",
  "period": "FY",
  "returnOnInvestedCapital": 0.5197,
  "returnOnEquity": 1.519,
  "returnOnAssets": 0.312,
  "enterpriseValue": 3895186810000,
  "evToSales": 9.36,
  "evToEBITDA": 26.97,
  "currentRatio": 0.893,
  "workingCapital": -17674000000,
  "marketCap": 3818743810000
}
```

**ratios — relevante felt bekreftet:**
```json
{
  "grossProfitMargin": 0.4691,
  "operatingProfitMargin": 0.3197,
  "netProfitMargin": 0.2692,
  "ebitdaMargin": 0.3470,
  "debtToEquityRatio": 1.524,
  "priceToEarningsRatio": 34.09,
  "priceToSalesRatio": 9.18,
  "priceToBookRatio": 51.79
}
```

⚠️ **`priceToEarningsRatio` i `ratios` er basert på periodeslutt-kurs** — IKKE point-in-time
per `decision_date`. Bruk KUN som referanse/kryssjekk. Kortets P/E beregnes ved seal i 04
fra `price(t0) / eps_diluted` (pipeline-prinsipp 3 i 03).

---

### Q21 🔴 Restatements
⚠️ **FMP eksponerer IKKE restatement-historikk som separate rader.**

Testing av 40 årsrader for AAPL og 30 årsrader for GE (kjent for restatements): **ingen
duplikat-perioder funnet**. FMP leverer kun én versjon per periode (antakelig siste kjente,
enten as-reported eller omarbeidet).

**Konsekvens for 02_datamodell (§3.3):** Den bitemporale nøkkelen
`(company_id, period_date, period_type, filing_date)` er fortsatt korrekt å implementere
(fremtidssikker), men i praksis vil FMP kun gi én rad per periode — ikke flere versjoner.
Skjemaet er klart, men feature-en aktiveres først hvis en bedre datakilde tilbys.

---

### Q22 ⚪ As-reported vs standardiserte statements
✅ Standardiserte statements har `filingDate` og `acceptedDate` — de holder for KAP.
`*-as-reported`-endepunktene er ikke nødvendige i v1.

---

## §3 Priser, total return & benchmark

### Q23 🔴 Utbyttejustert kurs — feltstruktur og responsform
✅ `GET /stable/historical-price-eod/dividend-adjusted?symbol=AAPL`

**Responsform:** Flat array av objekter (ikke nøstet `{symbol, historical:[...]}`).

**Feltliste (eksakt casing):**
```
symbol, date, adjOpen, adjHigh, adjLow, adjClose, volume
```

⚠️ **Merk:** `adjClose` — ikke `close` eller `adj_close`. Kun justerte verdier (ingen rå-OHLC).
For rå close trengs `historical-price-eod/full` (men den mangler adjClose — se Q27).

**Eksempel (nyeste rad, AAPL):**
```json
{"symbol": "AAPL", "date": "2026-06-17", "adjOpen": 300.85, "adjHigh": 302.07,
 "adjLow": 294.36, "adjClose": 295.95, "volume": 41784416}
```

**Eksempel (eldste rad uten from/to, AAPL):**
```json
{"symbol": "AAPL", "date": "2021-06-18", "adjClose": 127.15}
```
→ Uten `from/to` returneres kun ~1255 rader (≈5 år). Se Q24 for full historikk.

---

### Q24 🔴 from/to parametere
✅ **Bekreftet:** `from=YYYY-MM-DD` og `to=YYYY-MM-DD` virker.

```
?from=2020-01-01&to=2020-01-10 → 7 rader (kun handelsdager)
?from=1993-01-01&to=1993-12-31 → 234 rader (for SPY)
?from=1990-01-01&to=1990-12-31 → 253 rader (for AAPL)
```

⚠️ **KRITISK FOR PIPELINE:** Uten `from/to` er responsen begrenset til ~1255 rader (ca. 5 år).
Med `from/to` er **full historikk tilgjengelig tilbake til minst 1990** for store selskaper.
Pipeline MÅ bruke `from/to` ved backfill — ikke `limit=`.

**Inkrementell henting:** Bruk `from=<siste_lagrede_dato>` for å hente kun nye rader.

---

### Q25 🔴 SPY historikkdybde
✅ **SPY går tilbake til 1993** (børsnotering 22. januar 1993) med `from=1993-01-01`.

```
SPY: 234 rader for 1993, spenn: 1993-01-29 – 1993-12-31
```

Full historikk siden 1993 er tilgjengelig via `from/to`. Dette bekrefter at SPY-proxyen
dekker alle relevante batch-perioder for KAP (MVP: 2015–2020, med 5 års horisont → til 2025).

---

### Q26 🟡 Total-return semantikk — bekreftet ekte TR
✅ **`adjClose` fra `dividend-adjusted` er ekte total return** (utbytte reinvestert, ikke bare
justert for utbyttefallet).

Sjekk (SPY, 2005-01-03):
```
adjClose (dividend-adjusted): 81.39
close    (full/rå):           120.30
ratio:                        1.48x
```

Rå-close er 48 % høyere enn adjClose — all akkumulert utbytte siden 1993 er «trukket ut» bakover
i den justerte serien. Dette er standard backward-adjustment og gir ekte kumulativ total return
over hele perioden.

**Konsekvens:** `r_i = adjClose(t1) / adjClose(t0) - 1` gir korrekt totalavkastning inkl. utbytte.

---

### Q27 🟡 historical-price-eod/full — ingen adjClose
✅ Bekreftet: `full`-endepunktet har **ikke** `adjClose`.

**Felt i `full`:** `symbol, date, open, high, low, close, volume, change, changePercent, vwap`

**Konklusjon:** `full` brukes IKKE for avkastningsberegning. All TR-beregning (aksjer og benchmark)
hentes fra `dividend-adjusted`. `full` kan brukes for OHLC-diagram og splitt-deteksjon
(sammenlign rå `close`-hopp med `adjClose`-bevegelse).

---

### Q28 🟡 ^SP500TR historikk
❌ `^SP500TR` returnerer `status=402` (Premium-gated eller ikke tilgjengelig).
`%5ESP500TR` (URL-encoded) returnerer `status=200` men **tom array `[]`** — ingen data.

**Konklusjon:** TR-indeksen er ikke tilgjengelig som prisinstrument i FMP.
**SPY `adjClose` bekreftes som eneste benchmark** (jf. 03_pipeline §5.1).

---

### Q29 🟡 Historical market cap — til cap-kategori ved seal
✅ `GET /stable/historical-market-capitalization?symbol=AAPL`

**Feltstruktur:**
```json
{"symbol": "AAPL", "date": "2026-06-17", "marketCap": 4393135269930}
```

Felt: `symbol`, `date`, `marketCap`. Daglig granularitet. Aksepterer `from/to`.

⚠️ **Delistede symboler returnerer 0 rader** (testet SIVB → tom array).
For delistede beregnes cap ved seal fra `price(t0) × weightedAverageShsOutDil` —
`historical-market-capitalization` er et alternativ kun for aktive selskaper.

---

## §4 Økonomidata

### Q30 🔴 Treasury-rates — feltliste og 3M-kolonnen
✅ `GET /stable/treasury-rates?from=2020-01-01&to=2020-01-10`

**Alle felt:**
```
date, month1, month2, month3, month6, year1, year2, year3, year5, year7, year10, year20, year30
```

**3-måneders risikofri rente:** `month3` (eksempelverdi 2020-01-10: `1.54`)

Enhet: **prosent per år** (ikke desimal) — `1.54` betyr 1,54 %/år.
Daglig faktor: `(1 + rate/100)^(1/252) - 1`

---

### Q31 🟡 Treasury-rates historikkdybde
✅ **Dekker tilbake til 1990-01-02** (bekreftet med `from=1990-01-01&to=1990-12-31` → 250 rader).

Uten `from/to` returneres kun de siste ~66 dagene. Bruk alltid `from/to` ved historisk henting.

**Konklusjon:** Alle MVP-perioder (fra ~2015) er godt dekket.

---

### Q32 🔴 Gyldige `name`-verdier i economic-indicators
Testet og bekreftet virksomme `name`-verdier:

| `name` | Beskrivelse | Frekvens | Rader (uten from/to) |
|--------|-------------|----------|----------------------|
| `realGDP` | Realt BNP (kjeding, mrd. 2017-USD) | Kvartalsvis | 3 (siste 3 kvartaler) |
| `GDP` | Nominelt BNP | Kvartalsvis | 3 |
| `CPI` | Konsumprisindeks (nivå) | Månedlig | 10 |
| `inflationRate` | Inflasjon YoY (%) | Daglig? | 250 |
| `unemploymentRate` | Arbeidsledighet (%) | Månedlig | 10 |
| `federalFunds` | Federal funds rate (%) | Månedlig | 11 |

`inflation` (uten suffix) → tom array (ugyldig navn).

---

### Q33 🔴 Economic-indicators — responsstruktur og historikk
✅ Feltstruktur:
```json
{"name": "realGDP", "date": "2026-01-01", "value": 24152.656}
```

⚠️ **Kritisk begrensning:** Uten `from/to` returnerer endepunktet kun de siste 3–11 observasjonene
(avhengig av serie). Med `from/to` forventes full historikk — ikke verifisert dybde,
men FRED-fallback dekker historikken til 1947 om nødvendig.

**Makro-pipeline:** Bruk `from=<batchstart - 2 år>` for å hente tilstrekkelig historikk.

### Q34 🟡 Rente-regime: treasury-rates vs economic-indicators
✅ **Bruk `treasury-rates` (`month3`) for `rate_level` og `rate_direction`.**

Begrunnelse: `treasury-rates` er daglig granularitet og historikk til 1990; `federalFunds` fra
`economic-indicators` er månedlig og gir bare de siste 11 månedene uten `from/to`.
`treasury-rates.month3` er dessuten mer direkte relevant (markedsbasert, ikke sentralbankbeslutning)
og er konsekvent med `risk_free`-beregningen (Q30/Q31).

---

## §5 Profil & taksonomi

### Q35 🟡 Profile — komplett feltliste
✅ `GET /stable/profile?symbol=AAPL`

Alle forventede felt bekreftet:
```
symbol, price, marketCap, beta, lastDividend, range, change, changePercentage,
volume, averageVolume, companyName, currency, cik, isin, cusip,
exchangeFullName, exchange, industry, website, description, ceo,
sector, country, fullTimeEmployees, phone, address, city, state, zip,
image, ipoDate, defaultImage, isEtf, isActivelyTrading, isAdr, isFund
```

Merk: `sector` bruker **FMPs egne sektor-labels** (se Q36), IKKE GICS direkte.

---

### Q36 🟡 Sektorer og industrier
✅ **11 sektorer** (komplett liste):
```
Basic Materials, Communication Services, Consumer Cyclical, Consumer Defensive,
Energy, Financial Services, Healthcare, Industrials, Real Estate, Technology, Utilities
```

Disse matcher i stor grad GICS niveau 1, men med egne navn (f.eks. «Consumer Cyclical» ikke
«Consumer Discretionary», «Financial Services» ikke «Financials»).

**`sector_coarse`-mapping:** FMPs 11 sektorer er allerede grove nok til å bruke direkte —
unntak er `Technology` og `Communication Services` der industrinivå kan avsløre selskapet.
Konfig-tabellen `sector_coarse_map` bør ha egne overstyringer for disse.

---

## §6 Hendelser — M&A

### Q37 🟡 Mergers-acquisitions-search — søkelogikk
✅/⚠️ Endepunktet finnes men er **begrenset til navnesøk** (`name`-parameter).

- `targetedSymbol=SIVB` → HTTP 400 (ugyldig parameter — `name` er påkrevd)
- `name=SIVB` → 0 resultater (tickere ikke søkbart)
- `name=Silicon Valley Bank` → 0 resultater (data mangler for 2023-delistingene)

**Konklusjon:** M&A-endepunktet er ikke brukbart for systematisk klassifisering av
delisting-årsak (`acquired` vs `bankruptcy`). Fallback-strategi for 04_curator:

1. Sluttkurs nær null på `delisted_date` → `bankruptcy`
2. Selskapet finnes som `removedTicker` i `historical-sp500-constituent` med `reason` som
   inneholder «acquisition» / «merger» → `acquired`
3. Alt annet → `other`

`delisting_reason` settes `null` i v1 og klassifiseres ved seal.

---

## §7 Bulk & effektivitet

### Q38–Q39 ⚪ Bulk-endepunkter
❌ **Ingen bulk-endepunkter funnet på Premium.**

Alle testede paths returnerer `404`:
- `stable/batch-request-end-of-day-prices`
- `stable/bulk/income-statement`
- `stable/bulk/profile`
- `stable/bulk/key-metrics`
- `stable/bulk-historical-price`

**Konklusjon:** Backfill gjøres som per-symbol-kall med rate-limiting (700/min).
~1 000 selskaper × 5 endepunkter = 5 000 kall → ~7 minutters kjøretid. Helt akseptabelt.

---

## §8 Kartoteket v1.1

### Q40 ⚪ Earnings call transcripts
❌ `status=402` — **ikke på Premium.** Tilgjengelig på Ultimate-plan.

**Alternativ for Kartoteket:** AI-generert earnings-sammendrag kan produseres fra
nøkkeltall + narrativ (S7 i pipelinen), uten transkripsjon. En dedikert datakilde
(Quartr API, Seeking Alpha) vurderes i v1.1 hvis transkripsjon er nødvendig.

---

### Q41 ⚪ Revenue segmentering
✅ **Begge tilgjengelig på Premium.**

- `GET /stable/revenue-product-segmentation?symbol=AAPL` → produkt-segmenter per periode
- `GET /stable/revenue-geographic-segmentation?symbol=AAPL` → geografiske segmenter per periode

**Feltstruktur:**
```json
{
  "symbol": "AAPL", "fiscalYear": 2025, "period": "FY",
  "date": "2025-09-27",
  "data": {"Mac": 33708000000, "Service": 109158000000, ...}
}
```

Nyttig for Kartotekets forretnings-/segmentlag (§2D i Instructions) — batch-generer og cache.

---

### Q42 ⚪ Company screener
✅ **Virker på Premium.** Støttede filter-parametere bekreftet:

```
marketCapMoreThan, marketCapLessThan, sector, industry, beta(More/Less)Than,
country, exchange, isEtf, isFund, isActivelyTrading, limit
```

**Feltstruktur i respons:**
```
symbol, companyName, marketCap, sector, industry, beta, price,
lastAnnualDividend, volume, exchange, exchangeShortName, country,
isEtf, isFund, isActivelyTrading
```

Nyttig for screen-baserte Kartotek-decks («ROIC > 15 % i 10 år» krever key-metrics-join,
ikke screener alene, men markedsfiltere fungerer direkte).

---

## Oppsummering — konsekvenser for spec-arbeidet

### Grønne lys (bekreftet OK)
- ✅ Survivorship: `historical-sp500-constituent` gir full endringshistorikk tilbake til 1957
- ✅ Kurshistorikk for delistede selskaper virker på Premium (`adjClose` bekreftet)
- ✅ Look-ahead-vakten: `filingDate` konsekvent 3–5 uker etter periodeslutt
- ✅ Kvartalstall med `filingDate` tilgjengelig på Premium
- ✅ Regnskapshistorikk 40 år (back to 1986 for AAPL)
- ✅ SPY `adjClose` som TR-benchmark tilbake til 1993
- ✅ `from/to` på alle kursendepunkter — kritisk for full historikk
- ✅ `treasury-rates.month3` som risikofri rente tilbake til 1990
- ✅ Auth via HTTP-header virker

### Røde flagg / design-justeringer påkrevd
- ⚠️ **`delisted-companies` er et rullerende vindu (~4 mnd), ikke et historisk arkiv.**
  Survivorship-løsningen er `historical-sp500-constituent.removedTicker` — ikke `delisted-companies`.
  Pipeline S1 justeres: `delisted-companies` brukes kun for å sette `is_delisted`-flagg på *nylig*
  delistede; historiske delistede hentes fra konstituentloggen.

- ⚠️ **`dividend-adjusted` uten `from/to` gir kun 5 år.** Pipeline MÅ alltid sende `from/to`.
  Default-kall returnerer ikke full historikk.

- ⚠️ **BBBY-symptom: symbol-gjenbruk.** Kursserien for et gjenbrukt ticker inneholder data for
  to forskjellige selskaper. Pipeline må truncere serier på `delisted_date` per `company_id`.

- ⚠️ **Restatements ikke tilgjengelige** — bitemporalitet i skjemaet er fremtidssikring, ikke
  noe FMP leverer i dag.

- ❌ **Ingen bulk-endepunkter på Premium** — per-symbol-iterasjon er eneste vei.

- ❌ **M&A-klassifisering via API ikke mulig** — fallback: sluttkurs-heuristikk + `reason`-tekst
  fra konstituentloggen.

- ❌ **Earnings transcripts krever Ultimate** — alternativ for Kartoteket utsettes til v1.1.
