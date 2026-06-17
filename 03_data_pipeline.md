# 03_data_pipeline.md – KAP Spesifikasjon: Data Pipeline & Ingest

> **Dokumentserie:** `01_scoring` ✓ · `02_datamodell` ✓ · **`03_data_pipeline` (dette)** · `04_curator` · `05_api` · `06_frontend_gameloop` · `07_kartoteket` · `08_realtime`
> Denne spec'en definerer hvordan domene A–D (02 §2) befolkes: henting fra FMP (`stable`), point-in-time-disiplin, transformasjon, AI-generering med leak-sjekk, datakvalitetsport, og orkestrering. Den er skrevet mot **verifisert** FMP-virkelighet (probet juni 2026; endepunktliste i 05 §7–§9), ikke antakelser. **Forutsetter Premium-abonnement** (begrunnet i §2).

---

## 1. Designprinsipper

1. **Idempotens er ikke-forhandlbart.** Pipelinen må kunne kjøres om igjen – etter krasj, dobbelt, eller delvis – uten å duplisere eller korrumpere. All last skjer som `upsert` på naturlige nøkler. Et ETL-steg uten idempotens er en tikkende datakvalitetsbombe.
2. **Finans er append-only, aldri overskriv.** En restatement er en *ny rad* (ny `filing_date`), ikke en oppdatering. Vi sletter aldri «gamle» tall – det er nettopp de som var kjent på beslutningsdatoen (point-in-time, 02 §3.3).
3. **Pris-avhengige felt beregnes ved seal, ikke ved ingest.** Alt som krever en kurs på en *vilkårlig as-of-dato* (P/E, P/S, market cap → cap-kategori) kan ikke fryses i pipelinen, fordi kortets dato velges senere av Curator. Pipelinen lagrer *prisuavhengige* byggeklosser (per-aksje-tall, regnskapslinjer); multiplene regnes i 04 fra `price(t0)`. Dette er det viktigste korrekthetsskillet i hele datalaget (utdyper 02 §6).
4. **Skill fetch / transform / load.** Rå respons → validert → modellert. Rålaget bevares (replay/debug); transformasjon er ren og testbar; last er idempotent. «Behold det rå» gjør at en feil i transformasjonslogikken kan rettes uten å hente alt på nytt.
5. **Kvalitet er en port, ikke en ettertanke.** Tvilsomme data *karantenes* (ikke slettes stille). Curator kan ikke seal-e en batch som rører karantenerte/ufullstendige serier (02 §13). Stille feil er den dyreste feilen i en backtest.
6. **Proveniens på hver datum.** `source`, `fetched_at`, `api_version` følger med. Når et tall ser rart ut om seks måneder, skal vi kunne spore det til respons og tidspunkt.
7. **Rate-limit-bevisst og deterministisk.** Respekter kvoten (Premium: 750 kall/min), backoff på 429/5xx, eksplisitt håndtering av 402 (Premium-gated → logg, ikke hopp stille). Reproduserbarhet over ytelse.
8. **Anonymisering håndheves ved generering.** Et narrativ kan ikke brukes før det har bestått leak-sjekken (§7). Grensen settes i pipelinen, ikke i UI-et.

---

## 2. Verifisert FMP-virkelighet (låser antakelsene)

Probet mot Premium-relevante endepunkter. Dette er grunnlaget hele spec'en hviler på:

| Krav (Instructions §4) | Endepunkt (`stable`) | Status | Merknad |
|---|---|---|---|
| Survivorship – konstituenthistorikk | `GET /stable/historical-sp500-constituent` | ✅ | Inn-/utmeldingsdatoer → rekonstruér univers per dato |
| Survivorship – delistede + kurs | `GET /stable/delisted-companies` + `GET /stable/historical-price-eod/dividend-adjusted?symbol=` | ✅ **(Premium)** | Probe på Starter ga `402 "Premium Query Parameter"`. **Avhenger av aktivt Premium-abonnement.** |
| Look-ahead – filing dates | `GET /stable/income-statement?symbol=` har `filingDate`/`acceptedDate` | ✅ | Eksakt casing bekreftes i API Viewer (05 §7) |
| Totalavkastning – justert kurs | `GET /stable/historical-price-eod/dividend-adjusted?symbol=` | ✅ | Dedikert splitt+utbytte-justert endepunkt (ikke `…/full`) |
| Benchmark (TR) | `GET /stable/historical-price-eod/dividend-adjusted?symbol=SPY` | ✅ **(låst, #4)** | `^SP500TR` har grunn historikk; SPY-`adjClose` brukes som investerbar TR-proxy over hele spennet (begrunnet §5.1) |
| Risikofri + makro | `GET /stable/treasury-rates`, `GET /stable/economic-indicators` | ✅ | FMP single-vendor; FRED kun fallback (05 §9) |

**Base & paths:** `https://financialmodelingprep.com/stable/` (gjeldende; v3 er «legacy»). Den fulle, docs-grunnede endepunktlisten ligger i **05 §7–§9** og er autoritativ for denne spec'en. Probe-scriptet (`fmp_probe.py`) bør oppdateres til `stable`-stier og er sannhetskilden for hvilke paths/felt *din* nøkkel eksponerer.

---

## 3. Stadie-arkitektur (dataflyt)

```
FMP (stable) ──► [S0 Klient/fundament] ─► rå-landing (valgfri) ─► transformasjon ─► idempotent last
        │
        ▼
  S1 Univers (survivorship)      → companies(is_delisted), index_constituents
  S2 Entiteter                   → companies(sektor, sector_coarse, iconic, currency)
  S3 Finans (point-in-time)      → financials (append-only, m/ filing_date, shares_out)
  S4 Kurser (TR)                 → prices (adj_close)
  S5 Benchmark + risikofri       → index_prices (SPY-proxy), risk_free (FMP treasury-rates)
  S6 Makro                       → macro_context (FMP economic-indicators + AI-setning)
  S7 Narrativer + leak-sjekk     → narratives (kun leak_check_passed=true brukbare)
  S8 Datakvalitetsport           → data_quarantine + dekningssjekk (seal-precondition)
  S9 Orkestrering                → backfill (engang) / inkrementell (nattlig+kvartalsvis)
```

Avhengigheter: S1→S2→S3/S4 (entiteter før tall). S5/S6 er uavhengige (kan kjøre parallelt). S7 avhenger av S2+S3+S6 (trenger tall+makro for å skrive narrativ) og av Curators kandidatpool (§7.3). S8 leser alt. S9 styrer rekkefølge og inkrementalitet.

---

## 4. Stadie 0 – Klient & fundament

### 4.1 FMP-klient

Tynt lag med ett ansvar: hente robust og innenfor kvote.

```python
class FMPClient:
    def __init__(self, key, base="https://financialmodelingprep.com",
                 calls_per_min=700):           # 700 < 750-taket = margin
        ...
    def get(self, path, **params) -> list | dict:
        # - token-bucket rate limiter (calls_per_min)
        # - retry m/ eksponentiell backoff på 429 og 5xx (maks ~5 forsøk)
        # - 402  -> raise PremiumGatedError(path)   (IKKE stille skip)
        # - 401/403 -> raise AuthError              (feil nøkkel/plan)
        # - logg (path, status, ms) til ingestion_runs
```

**Hvorfor eksplisitt 402-håndtering:** Et stille skip på 402 ville gitt en *delvis* universbygging som ser komplett ut – og gjeninnført survivorship-bias snikende. Vi vil ha en høylytt feil som tvinger fram en bevisst beslutning.

### 4.2 Økonomidata (FMP single-vendor)

Risikofri rente + makro hentes fra FMPs egne økonomi-endepunkter (samme klient/nøkkel som resten — én leverandør, én rate-limit): `GET /stable/treasury-rates` (3M T-bill + alle løpetider) og `GET /stable/economic-indicators?name=…` (BNP, inflasjon, arbeidsledighet). Se 05 §9. *FRED beholdes kun som fallback* (`https://api.stlouisfed.org/fred/...`, serier `DTB3`/`CPIAUCSL`/`GDPC1`) hvis FMPs økonomiserier viser seg tynne for en periode.

### 4.3 Idempotent last & proveniens

* Alle `INSERT` er `INSERT ... ON CONFLICT (<naturlig nøkkel>) DO UPDATE/NOTHING`.
* `financials`: `ON CONFLICT (company_id, period_date, period_type, filing_date) DO NOTHING` – refetch av samme filing er no-op; restatement (ny `filing_date`) gir ny rad (prinsipp 2).
* Proveniens: kolonner `source text`, `fetched_at timestamptz`, `api_version text` på rå-/landingslaget; en `ingestion_runs(id, stage, started_at, finished_at, rows_in, rows_out, errors jsonb)` for observabilitet.
* **Rå-landing (anbefalt, valgfri MVP):** lagre rå JSON per `(endpoint, symbol, fetched_at)` (egen tabell eller objektlagring). Lar oss reparere transformasjonsfeil uten ny henting – billig forsikring.

---

## 5. Stadiene i detalj

### S1 – Univers (survivorship)

**Mål:** for enhver `decision_date D`, kunne svare hva som *faktisk var investerbart* da (02 §3.2/§4.2).

1. Hent nåværende S&P 500-konstituenter (`GET /stable/sp500-constituent`) + endringshistorikk (`GET /stable/historical-sp500-constituent`). Hver endring har dato + symbol (inn/ut).
2. Rekonstruér temporalt medlemskap: spol historikken bakover fra dagens liste, åpne/lukk `daterange`-intervaller → `index_constituents(index_code='SP500', company_id, membership)`.
3. Hent delistede (`GET /stable/delisted-companies`) → sett `companies.is_delisted=true`, `delisted_date`. **Årsak (konkurs/fusjon) leveres ikke** av endepunktet – men `acquired` vs `delisted` kan klassifiseres ved seal via M&A-endepunktet (`/stable/mergers-acquisitions-search`, 05 §8.6 / 04 §5.3); `delisting_reason` settes `null` i v1.
4. Hent ticker-endringer (`GET /stable/symbol-change`) for å holde `company_id`-mappingen korrekt ved symbolbytter (02 §4 ticker-gjenbruk).
5. Kurshistorikk for delistede hentes i S4 (Premium) – serien ender naturlig på `delisted_date`.

*Premium-avhengighet:* uten Premium gir steg 4 402 og survivorship-fiksen kollapser til «kun overlevere» (dokumentert i forrige sparring). Med Premium er den ekte.

### S2 – Entiteter

1. `GET /stable/profile?symbol=` → `companies`: navn, sektor, industri, land, valuta, market cap-kategori (referanse).
2. **`sector_coarse`** (anonymiseringstrygg): mapping FMP `sector`/`industry` → grov GICS-sektor, med sammenslåing der industrinivå er avslørende (02 §3, anonymiseringsregler). Konfig-tabell `sector_coarse_map`, ikke hardkodet.
3. **`iconic`-flagg:** seed med kuratert liste over de ~50 mest gjenkjennelige (AAPL, TSLA, AMZN, MSFT, NVDA, META, GOOGL, KO, …), augmentér med en heuristikk (topp-N på historisk market cap). Curator ekskluderer disse fra blind/daily (Instructions §3).
4. **MVP-filter:** kun USD/US-notert (02 §4 valuta-avgrensning). UK/Canada (Premium) er en senere løftestang.

### S3 – Finans (point-in-time, append-only)

Hent per selskap (`stable`): income statement (`/stable/income-statement`), balance sheet (`/stable/balance-sheet-statement`), cash flow (`/stable/cash-flow-statement`), key-metrics (`/stable/key-metrics`) — **både `period=annual` og `period=quarter`**, med `limit` høyt nok til ønsket dybde (Premium: opptil 30 år).

**Feltmapping (FMP → 02-skjema):**

| Vår kolonne | FMP-kilde | Notat |
|---|---|---|
| `period_date` | income `date` | periodeslutt (gyldighetstid) |
| `period_type` | income `period` | `FY`→annual, `Q1..Q4`→quarter |
| `filing_date` | `filingDate` (ev. dato-del av `acceptedDate`) | transaksjonstid (look-ahead-anker, §5-#5 låst på acceptedDate-basis); eksakt casing bekreftes i API Viewer (05 §7) |
| `revenue`, `net_income` | income `revenue`, `netIncome` | |
| `eps` | income `epsDiluted` (foretrekk diluted; bekreft casing) | |
| `shares_out` | income `weightedAverageShsOutDil` | **trengs for P/E, P/S, cap ved seal** (prinsipp 3) |
| `debt_to_equity` | beregn: `totalDebt / totalStockholdersEquity` (balance) | vi beregner selv → kontroll |
| `gross/operating/net_margin` | beregn fra income, ev. kryssjekk mot ratios | |
| `fcf` | cash flow `freeCashFlow` | |
| `roic` | key-metrics `roic` | FMP-levert; kryssjekk |
| `cap_category` | **referanse** (FMP), IKKE kortvendt | kortets cap regnes ved seal fra `price(t0)·shares` *eller* `historical-market-capitalization` (05 §8.5) |
| `pe`, `ps` | **referanse** (FMP, periodeslutt-basis), lagres i `extra` | **IKKE kortvendt** – kortets multipler regnes ved seal |

**Prisuavhengige avledninger (OK i pipeline):** 3-års CAGR på revenue/EPS regnes fra point-in-time-rader og kan fryses. **Prisavhengige (P/E, P/S, market cap → cap-kategori) regnes IKKE her** – kun ved seal i 04 (prinsipp 3).

**TTM:** for kvartalsbaserte multipler trengs TTM (rullerende 4 kvartaler). Beslutning (02 §14-6): pipelinen lagrer kvartalsrader rått; TTM-aggregering gjøres som en *avledning ved behov* (view/funksjon), ikke som lagrede `period_type='ttm'`-rader, for å unngå dobbel sannhet. Avledningen må selv respektere `filing_date` (kun kvartaler kjent ved `decision_date`). *FMPs `*-ttm`-endepunkter gir kun **nåtids**-TTM (ikke point-in-time) og brukes derfor bare til Kartoteket (05 §8.3) – aldri til historiske batcher.*

### S4 – Kurser (totalavkastning)

1. `GET /stable/historical-price-eod/dividend-adjusted?symbol=` → `prices(company_id, date, adj_close, close_raw)`. `adj_close` = utbyttejustert sluttkurs (splitt+utbytte; bekreft feltnavn i API Viewer, 05 §8.4). Rå OHLC fra `…/full` eller ujustert fra `…/non-split-adjusted` kun for debug/`close_raw`.
2. Hent for **hele universet inkl. delistede** (Premium). Delisted-serie ender på `delisted_date` – håndteres i avkastningsmotoren (01 §6, edge cases).
3. **Konsistens-krav (kritisk, #4):** samme leverandør og samme justeringsmetode for *både* aksjer og benchmark. Alpha = aksje-TR − benchmark-TR er kun meningsfull hvis teller og nevner er justert likt. Derav SPY-`adjClose` som benchmark (S5), ikke en indeks fra en annen kilde/metode.

### S5 – Benchmark + risikofri

#### 5.1 Benchmark (SPY-proxy, låst)

`GET /stable/historical-price-eod/dividend-adjusted?symbol=SPY` → `index_prices(index_code='SP500TR_SPY', date, tr_close=adj_close)`.

**Begrunnelse (oppfyller #4-kravene «nøyaktig, hele perioden, konsistent»):** `^SP500TR` har grunn historikk hos FMP; SPY-`adjClose` går tilbake til 1993, er utbyttejustert (ekte total return), og er *samme instrument og metode* som aksjedataene (S4) – maksimal konsistens og kryss-batch-sammenliknbarhet over et spenn godt lengre enn 6 år. Kostnaden er SPYs avgiftsdrift (~0,09 %/år), som er konstant og ubetydelig, og strengt tatt gjør benchmarket *investerbart* (et ærligere mål). VOO (2010+) er alternativ for nyere epoker, men SPY velges for maksimal historikk. Den lille driften dokumenteres i reveal-metodikken.

#### 5.2 Risikofri (FMP treasury-rates)

`GET /stable/treasury-rates` (3M-kolonne, forventet `month3`; bekreft i API Viewer) → `risk_free(date, tenor='3M', annual_rate)`. Daglig faktor på handelsdager: `(1+annual_rate)^(1/252)−1` (må matche 01 §2/§6.6). Curator fryser `R_f`/`r_f`/`alpha_cash` per batch fra denne serien. *FRED `DTB3` som fallback.*

### S6 – Makro (FMP economic-indicators + AI)

Makro er *regime-nivå*, ikke daglig. Beregn månedlig (kortet leser raden for `decision_date`s måned). Tallene lagres numerisk (Curator trenger dem til regime-/cash-optimalitets-logikk, 04 §4), men *vises som bånd* på kortet, og AI-setningen må bestå epoke-lekkasjesjekken (04 §5.7).

1. `rate_direction`: sammenlign 3M-rente (`treasury-rates`) mot ~12 mnd før → `rising/flat/falling`.
2. `rate_level`: terskler på absolutt nivå → `low/neutral/high` (konfig).
3. `inflation`, `gdp_growth`: fra `GET /stable/economic-indicators?name=…` (CPI/GDP, YoY; BNP kvartalsvis → forward-fill).
4. `ai_sentence`: batch-LLM tar de tørre tallene → én kontekstsetning *uten årstall* (Instructions §3), leak-sjekket (04 §5.7). Cached.

→ `macro_context(date, region='US', rate_level, rate_direction, inflation, gdp_growth, ai_sentence)`.

### S7 – Narrativer + leak-sjekk

**Mål:** for hvert kandidat-`(company, decision_date, horizon)` produsere `{narrative, sector_sentiment, clue, result_explanation}` (02 §7), anonymisert og leak-sjekket, batch-generert og cachet (aldri runtime, Instructions §5).

#### 7.1 Generering
LLM får point-in-time-tall (S3) + makro (S6) + (for clue/result_explanation) fasit-avkastning, og bes returnere **JSON** med de fire feltene. `narrative`/`sector_sentiment` er kortvendt og **strippet for navn/ticker/produkt/beløp**; `clue`/`result_explanation` er reveal-innhold.

#### 7.2 Leak-sjekk (to-trinns, hard port)
1. **Determinisk:** regex/strengmatch av `narrative`+`sector_sentiment` mot selskapsnavn, ticker, kjente produkt-/merkenavn (fra en alias-liste per selskap). Treff → underkjent.
2. **LLM-dommer:** gi *kun* det anonymiserte narrativet til en separat LLM-kall: «Kan du identifisere selskapet? Svar med kandidat + konfidens.» Høy konfidens / korrekt → underkjent.

Underkjente regenereres automatisk (maks N forsøk, så flagges for manuell review). Kun `leak_check_passed=true` kan inngå i en sealet batch (02 §7, §13).

**Epoke-lekkasjesjekk (andre dimensjon, 04 §5.7):** samme to-trinns mønster kjøres på `narrative`/`sector_sentiment` for *kalenderepoke*: regex mot epokedefinerende termer (pandemi, finanskrise, dot-com, Lehman, 9/11, Covid, krig) + LLM-dommer «kan du tidfeste dette til ±2 år?» → underkjent ved treff. Sammen med bånd-visning av makro-tallene (S6) lukker dette epoke-gjettings-kanalen.

#### 7.3 Kandidatpool (løser høna-og-egget)
Curator (04) trekker kort fra et univers, men narrativer må finnes *før* seal. Løsning: pipelinen pre-genererer narrativer for **det kvalifiserte universet per mål-`decision_date`** (avgrenset mengde, ikke alle selskap × alle datoer). Mål-datoene er en konfigurert liste (de periodene vi vil ha batcher fra). Kostnadskontroll: dette er den dominerende LLM-kostnaden – hold mål-dato-listen bevisst kort i MVP. *Alternativ (lat):* generér ved første seal-forsøk og cache; enklere, men gir latency-spiss ved seal. MVP: pre-generér for en liten mål-dato-liste.

### S8 – Datakvalitetsport & karantene

Valideringsregler (feil → `data_quarantine(table, row_ref, rule, detail, quarantined_at)`, ikke sletting):

* `filing_date >= period_date` (ellers korrupt point-in-time).
* Ingen negative/null-kurser; ingen `adj_close`-hopp > X % dag-til-dag uten tilsvarende `close_raw`-hopp (splittglitch).
* Prisserie-gap: ingen sammenhengende hull > 10 handelsdager i et batch-relevant vindu.
* Regnskap: ikke-negativ revenue der det ikke gir mening; `shares_out > 0`.
* Narrativ: `leak_check_passed=true`.

**Dekningssjekk (seal-precondition, 02 §13):** funksjon `coverage_ok(company_id, t0, H)` som verifiserer hullfrie `prices`/`index_prices`/`risk_free` over `[t0−2år, t1]` og bestått leak-sjekk. Curator kaller denne før seal.

### S9 – Orkestrering

* **Backfill (engang, tungt):** hele universet, full historikk. Rekkefølge S1→S2→S3/S4→S5/S6→S8. Ved ~1k selskaper × {income,balance,cashflow,metrics,prices} ≈ tusenvis av kall; på 700/min er det minutter, ikke timer. Kjør i symbol-batcher med checkpointing (gjenoppta etter avbrudd).
* **Inkrementelt (nattlig):** prices fra siste lagrede dato; økonomi-serier (`treasury-rates`/`economic-indicators`) oppdateres; konstituent- og `symbol-change`-lister diffes.
* **Kvartalsvis:** refetch siste ~2 kvartalers regnskap (fanger restatements via ny `filing_date`); generér narrativer for nye mål-datoer; refresh `company_profiles` (Kartoteket).
* **Reproduserbarhet:** hver kjøring logges i `ingestion_runs`; rå-landing + append-only finans gjør at en gitt batch kan rekonstrueres bit-eksakt.

---

## 6. Grensesnitt mot nabo-specs

**→ 02_datamodell:** skriver A–D + `data_quarantine` + `ingestion_runs`. *Avklaringer som oppdaterer 02:* (a) `financials.pe/ps/cap_category` er **referanse-only** (flyttes ev. til `extra`); kortets multipler/cap regnes ved seal. (b) Legg til `financials.shares_out` (fra `weightedAverageShsOutDil`) – nødvendig for seal-tids P/E, P/S, cap. (c) `index_prices.index_code = 'SP500TR_SPY'`.

**→ 04_curator:** leser `index_constituents` (univers per dato), `financials` (point-in-time via 02 §6.2-spørringen), `prices`/`index_prices`/`risk_free` (avkastning), `narratives` (leak-sjekket). Curator **beregner ved seal**: P/E, P/S, cap-kategori (fra `price(t0)·shares` el. `historical-market-capitalization`), per-kort alpha/avkastning, og fryser benchmark/rf. Kaller `coverage_ok` som seal-gate.

**→ 01_scoring:** garantien om «hullfrie serier `[t0−2år, t1]`» (01 §7) leveres av S4/S5 + S8-dekningssjekken. De to ekstra årene er ex-ante-kovariansens trailing-vindu (før `t0`, point-in-time-trygt).

---

## 7. Edge cases (ingest)

1. **Manglende/uventet filing-dato:** klienten leser `filingDate` (fallback dato-del av `acceptedDate`). Hvis begge mangler → karantene (kan ikke garantere point-in-time). Eksakt feltcasing bekreftes i API Viewer (05 §7).
2. **Delisted uten kurs (ikke-Premium):** 402 → `PremiumGatedError`, kjøring stopper høylytt (ikke delvis univers).
3. **Restatement:** ny `filing_date` for eksisterende periode → ny rad (append-only). Aldri overskriv.
4. **Manglende `shares_out`:** P/E/P/S/cap kan ikke regnes ved seal → kortet er ikke seal-bart (karantene-flagg).
5. **Hull i økonomi-serie (helligdager/forsinkelse):** forward-fill siste observasjon for daglige serier; flagg hvis > N dager gammel.
6. **Ticker-gjenbruk:** mappes til riktig `company_id` via partiell unik indeks (02 §4); delistet ticker som dukker opp igjen → nytt selskap, ny rad.
7. **Narrativ-lekkasje som ikke fikses på N forsøk:** flagg for manuell review; selskapet droppes fra kandidatpoolen for den datoen til løst.

---

## 8. Åpne beslutninger

1. **Rå-landing nå eller senere?** Anbefalt fra start (billig forsikring), men kan utsettes om MVP-tempo presser. Bekreft.
2. **`delisting_reason`:** la stå `null` i v1; fasit-event (`acquired`/`delisted`) klassifiseres ved seal via M&A-endepunktet (`mergers-acquisitions-search`, 05 §8.6), med kurs-heuristikk (sluttkurs nær null) som fallback. Påvirker oppkjøps-håndtering i 01 §6-2.
3. **LLM-leverandør/-modell for narrativer + dommer:** Instructions nevner OpenAI. Lås modell + at dommeren er et *separat* kall (helst annen modell/temperatur for uavhengighet). Din beslutning.
4. **Mål-dato-liste (kandidatpool):** hvilke `decision_date`/`horizon`-kombinasjoner i MVP? Avgjør LLM-kostnad. Forslag: 2–3 datoer (f.eks. 2016, 2018, 2019) med H=5.
5. **Alias-liste for leak-sjekk:** kilde for produkt-/merkenavn per selskap (manuell seed vs FMP/wiki-skrap)? Påvirker treffsikkerhet på trinn 1.

---

## 9. Test & fixtures

* **Kontraktstester mot rå-landing:** frys et lite sett ekte FMP-responser (inkl. ett delistet, ett oppkjøpt, ett med restatement) som fixtures; transformasjonen testes mot dem uten nettverk.
* **Point-in-time-test:** verifiser at 02 §6.2-spørringen mot seedet `financials` returnerer *kun* tall med `filing_date <= decision_date`, og riktig restatement-versjon.
* **Dekningssjekk-test:** en batch med et konstruert prisgap > 10 dager skal feile `coverage_ok`.
* **Leak-sjekk-test:** et narrativ som inneholder et kjent produktnavn skal underkjennes på trinn 1; et som navngir bransjeposisjon tydelig skal fanges på trinn 2.
* **Survivorship-røyktest:** `universe(2016-01-04)` skal inneholde minst ett selskap som senere ble delistet (ellers lekker dagens-liste-bias inn).
* Binder mot **golden fixtures (01 §3.3/§4.6)** og seed-universet (02 §15) i samme CI.