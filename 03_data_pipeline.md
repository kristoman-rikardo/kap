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

Probet **empirisk mot Premium-nøkkel (juni 2026)**. Dette er grunnlaget hele spec'en hviler på (fullstendige svar i `fmp_api_questions.md`):

| Krav (Instructions §4) | Endepunkt (`stable`) | Status | Merknad |
|---|---|---|---|
| **Survivorship – konstituenthistorikk** | `GET /stable/historical-sp500-constituent` | ✅ | **Den reelle survivorship-kilden.** 1 520 endringer tilbake til **1957**; hver rad = én bytte (`date`, `symbol`/added, `removedTicker`, `reason`). |
| Univers i dag | `GET /stable/sp500-constituent` | ✅ | 503 selskaper (referansepunkt for tilbake-spoling) |
| Nylig delistede (flagg) | `GET /stable/delisted-companies` | ⚠️ | **Rullerende ~4-mnd-vindu, IKKE arkiv** (eldste ≈ feb 2026). Brukes kun til `is_delisted`-flagg på nylige; historiske delistede kommer fra `removedTicker`-loggen. |
| **Kurs for delistede** | `GET /stable/historical-price-eod/dividend-adjusted?symbol=` | ✅ **(Premium)** | Verifisert for SIVB/FRC/BBBY. **Krever `from/to`** ellers kun ~5 år (Q24). |
| Look-ahead – filing dates | `GET /stable/income-statement?symbol=` → `filingDate`/`acceptedDate` | ✅ | Bekreftet ~34 dager etter periodeslutt; også på kvartalsrader og delistede |
| Totalavkastning – justert kurs | `GET /stable/historical-price-eod/dividend-adjusted?symbol=` | ✅ | Felt `adjClose` (ekte TR, verifisert); `…/full` har *ikke* `adjClose` |
| Benchmark (TR) | `GET /stable/historical-price-eod/dividend-adjusted?symbol=SPY` | ✅ **(låst, #4)** | SPY tilbake til **1993**. `^SP500TR` **ikke tilgjengelig** (402/tom) → SPY-`adjClose` er eneste TR-kilde (§5.1) |
| Risikofri | `GET /stable/treasury-rates` → `month3` | ✅ | **Prosent/år** (1,54 = 1,54 %), tilbake til **1990**; krever `from/to` |
| Makro | `GET /stable/economic-indicators?name=…` | ✅ | Navn: `realGDP`, `inflationRate`, `unemploymentRate`, `federalFunds`, `CPI`, `GDP`; krever `from/to` |
| Restatements | — | ❌ | FMP gir **én versjon per periode** (ingen restatement-historikk). Bitemporal nøkkel er fremtidssikring (§5.3). |
| Bulk | — | ❌ | Ingen bulk-endepunkter på Premium; backfill = per-symbol (§9) |

**Base & paths:** `https://financialmodelingprep.com/stable/` (gjeldende; v3 er «legacy»). Autoritativ endepunktliste i **05 §7–§9**. Auth via HTTP-header `apikey:` (verifisert). Feilklasser: `401`→`AuthError`, `402`→`PremiumGatedError`, `429`→backoff.

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

Risikofri rente + makro hentes fra FMPs egne økonomi-endepunkter (samme klient/nøkkel — én leverandør, én rate-limit): `GET /stable/treasury-rates` (kolonne `month3` = 3M, **i prosent/år**, tilbake til 1990) og `GET /stable/economic-indicators?name=…` med navnene `realGDP`, `inflationRate` (YoY %), `unemploymentRate`, `federalFunds`, `CPI`, `GDP`. **Begge krever `from/to`** — uten gir treasury bare ~66 siste dager og economic-indicators bare 3–11 siste observasjoner. Se 05 §9. *FRED beholdes kun som fallback* hvis en FMP-serie viser seg tynn.

### 4.3 Idempotent last & proveniens

* Alle `INSERT` er `INSERT ... ON CONFLICT (<naturlig nøkkel>) DO UPDATE/NOTHING`.
* `financials`: `ON CONFLICT (company_id, period_date, period_type, filing_date) DO NOTHING` – refetch av samme filing er no-op; restatement (ny `filing_date`) gir ny rad (prinsipp 2). *Merk (verifisert Q21): FMP eksponerer i praksis kun **én versjon per periode** – ingen restatement-historikk. Append-on-restatement er derfor fremtidssikring som først aktiveres med en rikere kilde.*
* Proveniens: kolonner `source text`, `fetched_at timestamptz`, `api_version text` på rå-/landingslaget; en `ingestion_runs(id, stage, started_at, finished_at, rows_in, rows_out, errors jsonb)` for observabilitet.
* **Rå-landing (anbefalt, valgfri MVP):** lagre rå JSON per `(endpoint, symbol, fetched_at)` (egen tabell eller objektlagring). Lar oss reparere transformasjonsfeil uten ny henting – billig forsikring.

---

## 5. Stadiene i detalj

### S1 – Univers (survivorship)

**Mål:** for enhver `decision_date D`, kunne svare hva som *faktisk var investerbart* da (02 §3.2/§4.2).

**Reell kilde (verifisert):** survivorship for S&P 500 bygges fra **endringsloggen** `historical-sp500-constituent` (1 520 rader tilbake til 1957), *ikke* fra `delisted-companies` (som er et rullerende ~4-mnd-vindu, ikke et arkiv – Q11). MVP er avgrenset til S&P 500-universet; small-caps som aldri var i indeksen dekkes ikke, og det er akseptabelt.

1. Hent dagens liste (`GET /stable/sp500-constituent`, 503 selskaper) + endringsloggen (`GET /stable/historical-sp500-constituent`). **Hver logg-rad = én bytte:** `date` (ikrafttredelse), `symbol` (lagt til), `removedTicker`/`removedSecurity` (fjernet), `reason` (fritekst, f.eks. «acquisition by Devon Energy»).
2. Rekonstruér temporalt medlemskap: start fra dagens liste og **spol bakover** ved å reversere hver endring med `date > D` (legg tilbake `removedTicker`, fjern `symbol`) → `index_constituents(index_code='SP500', company_id, daterange)`.
3. **Historiske delistede/utgåtte** identifiseres fra `removedTicker`-loggen (selskaper som forlot indeksen). Sett `companies.is_delisted=true` for de som ikke er i dagens liste; `delisted_date` ≈ logg-`date` (indeks-exit), forfinet til faktisk siste handelsdag fra der kursserien ender (S4).
4. **Nylig delistede (flagg):** `GET /stable/delisted-companies` brukes *kun* til å oppdatere `is_delisted`/`delisted_date` på selskaper delistet de siste ~4 mnd. Paginér med dedup på `symbol` (overlapp observert mellom sider – Q5).
5. **`delisting_reason`/event:** klassifiseres ved seal (04 §5.3) fra logg-`reason`-teksten (inneholder «acquisition»/«merger» → `acquired`) + sluttkurs-nær-null-heuristikk (→ `bankruptcy`); **M&A-endepunktet er ikke brukbart** (kun navnesøk, mangler data – Q37). `delisting_reason` lagres `null` i v1.
6. **Ticker-gjenbruk:** `symbol-change` er også rullerende (~mar 2026, Q14) → brukes kun til nylige navnebytter. Historisk ticker-mapping bygges fra `removedTicker`-loggen. Et gjenbrukt symbol (f.eks. BBBY, Q12) får egen `company_id`; kursserien **trunkeres på `delisted_date`** per `company_id` (S4).
7. Kurshistorikk for delistede hentes i S4 (Premium, med `from/to`) – serien ender naturlig ved delisting.

*Premium-avhengighet:* delisted-kurser krever Premium (verifisert SIVB/FRC/BBBY); uten kollapser survivorship-fiksen til «kun overlevere».

### S2 – Entiteter

1. `GET /stable/profile?symbol=` → `companies`: navn, sektor, industri, land, valuta, market cap-kategori (referanse).
2. **`sector_coarse`** (anonymiseringstrygg): mapping FMP `sector`/`industry` → grov GICS-sektor, med sammenslåing der industrinivå er avslørende (02 §3, anonymiseringsregler). Konfig-tabell `sector_coarse_map`, ikke hardkodet.
3. **`iconic`-flagg:** seed med kuratert liste over de ~50 mest gjenkjennelige (AAPL, TSLA, AMZN, MSFT, NVDA, META, GOOGL, KO, …), augmentér med en heuristikk (topp-N på historisk market cap). Curator ekskluderer disse fra blind/daily (Instructions §3).
4. **MVP-filter:** kun USD/US-notert (02 §4 valuta-avgrensning). UK/Canada (Premium) er en senere løftestang.

### S3 – Finans (point-in-time, append-only)

Hent per selskap (`stable`): income statement (`/stable/income-statement`), balance sheet (`/stable/balance-sheet-statement`), cash flow (`/stable/cash-flow-statement`), key-metrics + ratios (`/stable/key-metrics`, `/stable/ratios`) — **både `period=annual` og `period=quarter`**, med `limit` for ønsket dybde (verifisert: `limit=40` → 40 årsrader, AAPL tilbake til **1986**; statements bruker `limit`, ikke `from/to`).

**Feltmapping (FMP → 02-skjema):**

| Vår kolonne | FMP-kilde | Notat |
|---|---|---|
| `period_date` | income `date` | periodeslutt (gyldighetstid) |
| `period_type` | income `period` | `FY`→annual, `Q1..Q4`→quarter |
| `filing_date` | `filingDate` (fallback: dato-del av `acceptedDate`) | transaksjonstid (look-ahead-anker; verifisert ~34 dager etter periodeslutt, også på kvartal/delistede) |
| `revenue`, `net_income` | income `revenue`, `netIncome` | |
| `eps` | income `epsDiluted` (foretrekk diluted; `eps` er basic) | |
| `shares_out` | income `weightedAverageShsOutDil` | **trengs for P/E, P/S, cap ved seal** (prinsipp 3) |
| `debt_to_equity` | beregn: `totalDebt / totalStockholdersEquity` (balance) | `totalDebt` levert direkte (kort+lang); vi beregner → kontroll |
| `gross/operating/net_margin` | beregn (`grossProfit/revenue` osv.) el. ratios `grossProfitMargin`/`operatingProfitMargin`/`netProfitMargin` | marginer finnes *ikke* i income-statement |
| `fcf` | cash flow `freeCashFlow` | |
| `roic` | key-metrics **`returnOnInvestedCapital`** | FMP-levert (feltnavnet er ikke `roic`); kryssjekk |
| `cap_category` | **referanse** (FMP), IKKE kortvendt | kortets cap regnes ved seal fra `price(t0)·weightedAverageShsOutDil` (aktive: ev. `historical-market-capitalization`, men den gir 0 rader for delistede – 05 §8.5) |
| `pe`, `ps` | **referanse** (ratios `priceToEarningsRatio`/`priceToSalesRatio`, periodeslutt-basis), lagres i `extra` | **IKKE kortvendt** – kortets multipler regnes ved seal |

**Prisuavhengige avledninger (OK i pipeline):** 3-års CAGR på revenue/EPS regnes fra point-in-time-rader og kan fryses. **Prisavhengige (P/E, P/S, market cap → cap-kategori) regnes IKKE her** – kun ved seal i 04 (prinsipp 3).

**TTM & Q4-fellen (viktig):** for kvartalsbaserte multipler trengs TTM (rullerende 4 kvartaler), men en naiv `Q1+Q2+Q3+Q4`-summering er *farlig*: Q4 bærer ofte årlige revisjoner/nedskrivninger, så summen spriker fra selskapets rapporterte FY. To strategier:

* **MVP (robust, anbefalt):** Curator forankrer `decision_date` **rett etter FY-`filingDate`** (04 §4) → bruk **FY-tallene direkte**, ingen TTM-aggregering. Sidesteg hele Q4-problemet, og passer MVPs kuraterte dato-sett (én post-FY-dato per selskap-år er rikelig).
* **Skalert (kontinuerlig drift):** bruk `TTM = siste FY + inneværende YTD − fjorårets YTD-på-samme-punkt` (bygger på selskapets egne YTD-tall som avstemmer mot FY), ikke 4-kvartals-sum. *Forbehold:* dette krever **YTD-tall**; FMPs standardiserte kvartaler kan være *diskrete* (per-kvartal) – verifiser om FMPs Q4 = `FY − 9M` (en plugg, som da ville avstemme per konstruksjon) eller en uavhengig figur, før 4-kvartals-sum stoles på.

Uansett strategi: aggregeringen er en *avledning ved behov* (view/funksjon), ikke lagrede `period_type='ttm'`-rader (02 §14-6, unngår dobbel sannhet), og må respektere `filing_date`. *FMPs `*-ttm`-endepunkter gir kun **nåtids**-TTM – kun Kartoteket (05 §8.3), aldri historiske batcher.*

### S4 – Kurser (totalavkastning)

1. `GET /stable/historical-price-eod/dividend-adjusted?symbol=&from=&to=` → `prices(company_id, date, adj_close, close_raw)`. Responsen er en **flat array** med felt `symbol, date, adjOpen, adjHigh, adjLow, adjClose, volume`; `adj_close` = `adjClose` (ekte total return, verifisert Q26). Rå `close` for `close_raw`/splitt-deteksjon hentes fra `…/full` (som *mangler* `adjClose` – Q27).
2. **`from/to` er obligatorisk (Q24):** uten dem returnerer endepunktet kun ~5 år (~1255 rader). Backfill bruker `from=<periodestart−2år>&to=<t1>`; inkrementelt `from=<siste lagrede dato>`. Aldri `limit`.
3. Hent for **hele universet inkl. delistede** (Premium). Delisted-serie ender naturlig ved delisting; **trunkér på `delisted_date` per `company_id`** for å unngå at en gjenbrukt ticker (BBBY, Q12) blander to selskapers data inn i samme serie.
4. **Konsistens-krav (kritisk, #4):** samme leverandør og justeringsmetode for *både* aksjer og benchmark. Alpha = aksje-TR − benchmark-TR er kun meningsfull hvis teller og nevner er justert likt. Derav SPY-`adjClose` som benchmark (S5).

### S5 – Benchmark + risikofri

#### 5.1 Benchmark (SPY-proxy, låst)

`GET /stable/historical-price-eod/dividend-adjusted?symbol=SPY&from=&to=` → `index_prices(index_code='SP500TR_SPY', date, tr_close=adjClose)`. SPY-historikk verifisert tilbake til **1993**.

**Begrunnelse (oppfyller #4-kravene «nøyaktig, hele perioden, konsistent»):** `^SP500TR` er **ikke tilgjengelig** hos FMP (verifisert Q28: 402/tom array) – SPY-`adjClose` er derfor eneste TR-kilde. Den går tilbake til 1993, er ekte total return (verifisert: SPY 2005-adjClose er 48 % under rå `close`, dvs. akkumulert utbytte trukket bakover – Q26), og er *samme instrument og metode* som aksjedataene (S4) → maksimal konsistens og kryss-batch-sammenliknbarhet. Kostnaden er SPYs avgiftsdrift (~0,09 %/år), som er konstant, ubetydelig, og strengt tatt gjør benchmarket *investerbart* (et ærligere mål). Driften dokumenteres i reveal-metodikken.

#### 5.2 Risikofri (FMP treasury-rates)

`GET /stable/treasury-rates?from=&to=` → `risk_free(date, tenor='3M', annual_rate)`, kolonne **`month3`**. **Enhet: prosent/år** (verifisert Q30 – `1.54` betyr 1,54 %/år), så daglig faktor på handelsdager er `(1 + annual_rate/100)^(1/252) − 1` (NB `/100`; må matche 01 §2/§6.6). Historikk tilbake til **1990**; `from/to` obligatorisk (uten: kun ~66 siste dager). Curator fryser `R_f`/`r_f`/`alpha_cash` per batch. *FRED `DTB3` som fallback.*

### S6 – Makro (FMP economic-indicators + AI)

Makro er *regime-nivå*, ikke daglig. Beregn månedlig (kortet leser raden for `decision_date`s måned). Tallene lagres numerisk (Curator trenger dem til regime-/cash-optimalitets-logikk, 04 §4), men *vises som bånd* på kortet, og AI-setningen må bestå epoke-lekkasjesjekken (04 §5.7).

1. `rate_direction`: sammenlign `treasury-rates.month3` mot ~12 mnd før → `rising/flat/falling` (treasury foretrekkes framfor `federalFunds`: daglig + historikk til 1990 + markedsbasert – Q34).
2. `rate_level`: terskler på absolutt `month3`-nivå → `low/neutral/high` (konfig).
3. `inflation`: `economic-indicators?name=inflationRate` (YoY %, daglig). `gdp_growth`: `name=realGDP` (kvartalsvis → YoY + forward-fill). **`from/to` obligatorisk** (uten: kun 3–11 siste obs – Q33). Gyldige navn: `realGDP`, `GDP`, `CPI`, `inflationRate`, `unemploymentRate`, `federalFunds`.
4. `ai_sentence`: batch-LLM tar de tørre tallene → én kontekstsetning *uten årstall* (Instructions §3), leak-sjekket (04 §5.7). Cached.

→ `macro_context(date, region='US', rate_level, rate_direction, inflation, gdp_growth, ai_sentence)`.

### S7 – Narrativer + leak-sjekk

**Mål:** for hvert kandidat-`(company, decision_date, horizon)` produsere `{narrative, sector_sentiment, clue, result_explanation}` (02 §7), anonymisert og leak-sjekket, batch-generert og cachet (aldri runtime, Instructions §5).

#### 7.1 Generering
LLM får point-in-time-tall (S3) + makro (S6) + (for clue/result_explanation) fasit-avkastning, og bes returnere **JSON** med de fire feltene. `narrative`/`sector_sentiment` er kortvendt og **strippet for navn/ticker/produkt/beløp**; `clue`/`result_explanation` er reveal-innhold.

**Hindsight-vakt (strukturell, ikke bare prompt):** `narrative`/`sector_sentiment` genereres fra **utelukkende point-in-time-input** – ingen data med dato/`filing_date` > `decision_date`, og **aldri** fasit-avkastningen, mates inn i kort-narrativets prompt. Utfallsdata går *kun* til `clue`/`result_explanation` (reveal-only). Det er en arkitekturgaranti som er sterkere enn en prompt-formaning. Prompten forsterker den eksplisitt: «skriv som en analytiker som står *på* denne datoen og *ikke kan vite* hva som skjer videre – beskriv bildet slik det var der og da, aldri i etterpåklokskap.» Ingen «slik gikk det / som det viste seg»-formuleringer i kortvendt tekst. (Hvis et nyhets-/kontekstinnspill brukes, må det ha hard as-of-grense ≤ `decision_date` og samme leak-/epoke-sjekk som resten – §7.2 / 04 §5.7.)

#### 7.2 Leak-sjekk (to-trinns, hard port)
1. **Determinisk:** regex/strengmatch av `narrative`+`sector_sentiment` mot selskapsnavn, ticker, kjente produkt-/merkenavn (fra en alias-liste per selskap). Treff → underkjent.
2. **Adversariell LLM-dommer:** en standard «er dette anonymisert?»-dommer er for overbærende. Gi i stedet *kun* det anonymiserte narrativet til et separat kall med en **adversariell** systemprompt: *«Du er en kynisk finanshistoriker. Gjett hvilket selskap dette er ut fra de underliggende mønstrene – du belønnes for å treffe. List dine 3 beste gjetninger.»* Er det korrekte selskapet blant **topp-3** → underkjent, og narrativet regenereres på et høyere abstraksjonsnivå. (Adversariell framing eliciterer modellens faktiske gjettekapasitet, ikke en mild dom.)

Underkjente regenereres automatisk (maks N forsøk, så flagges for manuell review). Kun `leak_check_passed=true` kan inngå i en sealet batch (02 §7, §13).

**Epoke-lekkasjesjekk (andre dimensjon, 04 §5.7):** samme to-trinns mønster med **samme adversielle framing** kjøres på `narrative`/`sector_sentiment` for *kalenderepoke*: regex mot epokedefinerende termer (pandemi, finanskrise, dot-com, Lehman, 9/11, Covid, krig) + adversariell dommer «tidfest dette så presist du kan – du belønnes for å treffe innen ±2 år». Treff innen båndet → underkjent. Sammen med bånd-visning av makro-tallene (S6) lukker dette epoke-gjettings-kanalen.

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

* **Backfill (engang, tungt):** hele universet, full historikk via `from/to`. Rekkefølge S1→S2→S3/S4→S5/S6→S8. **Ingen bulk-endepunkter på Premium (verifisert Q38)** → per-symbol-iterasjon. Ved ~1k selskaper × {income,balance,cashflow,metrics,ratios,prices} ≈ 5–6k kall; på 700/min ≈ 7–10 minutter. Symbol-batcher med checkpointing (gjenoppta etter avbrudd).
* **Inkrementelt (nattlig):** prices `from=<siste lagrede dato>`; økonomi-serier (`treasury-rates`/`economic-indicators`) oppdateres med `from/to`; dagens `sp500-constituent` diffes mot loggen; `delisted-companies` + `symbol-change` (rullerende) sjekkes for *nylige* endringer.
* **Kvartalsvis:** refetch siste ~2 kvartalers regnskap; generér narrativer for nye mål-datoer; refresh `company_profiles` (Kartoteket). *Merk: refetch fanger i praksis ikke restatements (FMP gir én versjon per periode, Q21) – det fanger nye/sent innleverte perioder.*
* **Reproduserbarhet:** hver kjøring logges i `ingestion_runs`; rå-landing + append-only finans gjør at en gitt batch kan rekonstrueres bit-eksakt.

---

## 6. Grensesnitt mot nabo-specs

**→ 02_datamodell:** skriver A–D + `data_quarantine` + `ingestion_runs`. *Avklaringer som oppdaterer 02:* (a) `financials.pe/ps/cap_category` er **referanse-only** (flyttes ev. til `extra`); kortets multipler/cap regnes ved seal. (b) Legg til `financials.shares_out` (fra `weightedAverageShsOutDil`) – nødvendig for seal-tids P/E, P/S, cap. (c) `index_prices.index_code = 'SP500TR_SPY'`.

**→ 04_curator:** leser `index_constituents` (univers per dato), `financials` (point-in-time via 02 §6.2-spørringen), `prices`/`index_prices`/`risk_free` (avkastning), `narratives` (leak-sjekket). Curator **beregner ved seal**: P/E, P/S, cap-kategori (fra `price(t0)·weightedAverageShsOutDil`; `historical-market-capitalization` kun for aktive – 0 rader for delistede), per-kort alpha/avkastning, event-klassifisering (logg-`reason` + sluttkurs-heuristikk, *ikke* M&A-endepunkt), og fryser benchmark/rf. Kaller `coverage_ok` som seal-gate.

**→ 01_scoring:** garantien om «hullfrie serier `[t0−2år, t1]`» (01 §7) leveres av S4/S5 + S8-dekningssjekken. De to ekstra årene er ex-ante-kovariansens trailing-vindu (før `t0`, point-in-time-trygt).

---

## 7. Edge cases (ingest)

1. **Manglende/uventet filing-dato:** klienten leser `filingDate` (fallback dato-del av `acceptedDate`). Hvis begge mangler → karantene. (Feltnavn/casing bekreftet Q15/Q16.)
2. **Delisted uten kurs (ikke-Premium):** 402 → `PremiumGatedError`, kjøring stopper høylytt (ikke delvis univers).
3. **Restatement:** skjemaet tar ny rad ved ny `filing_date`, men FMP gir i praksis kun én versjon per periode (Q21) – ingen handling kreves i dag.
4. **Manglende `shares_out`:** P/E/P/S/cap kan ikke regnes ved seal → kortet er ikke seal-bart (karantene-flagg).
5. **Hull i økonomi-serie (helligdager/forsinkelse):** forward-fill siste observasjon for daglige serier; flagg hvis > N dager gammel.
6. **Ticker-gjenbruk (verifisert BBBY, Q12):** mappes til riktig `company_id` via partiell unik indeks (02 §4); kursserie trunkeres på `delisted_date` per `company_id` så to selskaper ikke blandes.
7. **Historiske delistede mangler i `delisted-companies`:** endepunktet er rullerende (~4 mnd, Q11) → bruk `removedTicker`-loggen som survivorship-kilde (S1).
8. **Narrativ-lekkasje som ikke fikses på N forsøk:** flagg for manuell review; selskapet droppes fra kandidatpoolen for den datoen til løst.

---

## 8. Åpne beslutninger

1. **Rå-landing nå eller senere?** Anbefalt fra start (billig forsikring), men kan utsettes om MVP-tempo presser. Bekreft.
2. **`delisting_reason`:** la stå `null` i v1; fasit-event klassifiseres ved seal fra `historical-sp500-constituent.reason` («acquisition»/«merger» → `acquired`) + sluttkurs-nær-null → `bankruptcy`, ellers `other`. **M&A-endepunktet er verifisert ubrukbart** for dette (kun navnesøk, manglende data – Q37). Påvirker oppkjøps-håndtering i 01 §6-2.
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