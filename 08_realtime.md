# 08_realtime.md – KAP Spesifikasjon: Real-Time Mode (løpende anonymisert portefølje)

> **Dokumentserie:** `01_scoring` ✓ · `02_datamodell` ✓ · `03_data_pipeline` ✓ · `04_curator` ✓ · `05_api` ✓ · `06_frontend_gameloop` ✓ · `07_kartoteket` ✓ · **`08_realtime` (dette)**
> Den siste og mest ambisiøse modusen. **Scope-gated til sist** (Instructions §2C): dette er i praksis en egen app (løpende data, varsler, porteføljeforvaltning, anti-gaming), og bygges først når Junior + Kartoteket har bevist retention. Dokumentet er en forover-rettet, men konkret arkitektur. Bygger tungt på **01 §5** (scoring-skissen), **blind-pipelinen** (03/04 – anonymisering, point-in-time, leak-sjekk), og **02** (nye `rt_*`-tabeller).

---

## 1. Designprinsipper

1. **Ikke et nytt beist – blindmotoren i kontinuerlig modus.** Real-Time gjenbruker hele blindspillets maskineri (point-in-time, anonymisering, leak-sjekk, normalisering, IR-scoring) men kjører det *åpent og løpende* i stedet for i diskrete `H`-batcher. Forskjellen er *formen* (én levende portefølje over kalendertid, med earnings-events som ankommer) – ikke motoren.
2. **Etterslep-bufferen er anonymitetsmekanismen for nær-sanntid** *(din nøkkelbeslutning)*. Å anonymisere *live* data er lekkasje-utsatt (distinkte kursbevegelser, rapporteringsdato og nyheter røper selskapet). Løsning: hele opplevelsen kjører på en **klokke forskjøvet ~ett kvartal bakover** (`game_now = real_now − Δ`, `Δ ≈ 1 kvartal`, config), og kursen vises **normalisert/rebasert** (ingen absolutt nivå). Dette lukker tre lekkasjekanaler samtidig: (a) co-bevegelse med dagens nyheter, (b) rapporteringsdato-kalenderen, (c) absolutt prisnivå. **Elegant bivirkning:** earnings-utfall innenfor etterslepet er *allerede kjent* for systemet → deterministisk, umiddelbar scoring uten live-estimatfeed (§6). Navn avsløres først ved salg (Instructions §2C).
3. **Langsiktig etos, ikke day-trading.** EOD-NAV (ingen tick-jakt), 30-dagers karantene etter salg, obligatoriske begrunnelses-tags som tvinger tese-artikulering. Anti-dopamin, jf. 06 §1 – «motivere Warren Buffetter, ikke multi-screen TikTok-guruer».
4. **Prosess > utfall; kalibrering.** Scores på **rullerende IR** (ikke totalavkastning) + **Brier** (v1.1) – seleksjon og kalibrering, ikke flaks. Korte vinduer merkes «lav signifikans» (90-dagers IR er mest støy – si det høyt, 01 §5).
5. **Virtuelle penger, ikke investeringsråd.** Tydelige guardrails (§11); resultatlister er sekundære, indeks og læring er hovedfokus.
6. **Scope-gate.** Egen app, bygges sist. v1 her er allerede stort; v1.1 legger Brier.

---

## 2. Tidsmodell – etterslep-bufferen

* **Spillklokke:** `game_now = real_now − Δ`, `Δ ≈ 1 kvartal` (≈ én earnings-syklus; config). *Alt* presenteres as-of `game_now`: kurser, fundamentaler, makro, nyheter/events. Ettersom kalendertid går, glir `game_now` framover dag for dag – nye events ankommer løpende.
* **Hvorfor ett kvartal:** kort nok til å føles nær-nåtid (du handler selskaper omtrent som de er nå), langt nok til at (a) live-co-bevegelser ikke kan kryssrefereres, og (b) hvert holdt selskaps neste rapport ligger *innenfor* bufferen → utfallet er kjent når brukeren spår (men ukjent *for brukeren*, som er det kalibrering krever).
* **Konsekvens for data:** Real-Time trenger **ingen** ekte sanntids-kursfeed og **ingen** live konsensus-estimater for kjerneloopen – det kjører på lagrede EOD-serier opp til `game_now`. (Ekte sanntid ville krevd begge og kunne ikke scores før rapport faller; bevisst utenfor v1 – §13.)
* **Distinkt fra historiespillet:** samme motor, men (1) kontinuerlig/åpen i stedet for diskret `H`; (2) levende portefølje med NAV og rullerende IR; (3) earnings-events som ankommer mens du holder; (4) nær-nåtid (et kvartal bak), ikke «2014».

---

## 3. Anonymisering for nær-sanntid

Gjenbruker blindspillets anonymisering og **legger til** to nær-sanntids-spesifikke forsvar. Full stack:

1. **Ingen navn/ticker** på kortet; avsløres først ved salg (Instructions §2C). Truth er service-only (§7, samme grense som 02 §10 `batch_cards`).
2. **Normalisert/rebasert kurs** *(din beslutning)*: porteføljens og hver posisjons utvikling vises indeksert (rebasert til 100 ved kjøp, ev. % siden kjøp) – **aldri absolutt nivå**. Hindrer både prisnivå-fingeravtrykk og «P/E × shares»-identifikasjon.
3. **Etterslep-buffer** (§2): ingen live-co-bevegelse mot dagens nyheter; rapporteringsdato-kalenderen er forskjøvet.
4. **Bånd-vist makro + indeksert omsetning + ingen absolutte beløp** (Instructions §3, som blindkortet).
5. **Leak-sjekk på alt narrativt** (03 §7.2 adversariell dommer) + **epoke-anonymitet** på makro/sentiment (04 §5.7) – men her er «epoken» nær-nåtid, så epoke-dommeren tidfester mot `game_now ± bånd` heller enn en historisk epoke.
6. **Earnings-reveal uten navn:** når et hold rapporterer, vises utfallet anonymisert («din posisjon slo konsensus, omsetning +12 % å/å») uten å røpe selskapet. Anonymiteten hviler ellers på universstørrelse (mange selskaper), som i blindspillet.

---

## 4. Portefølje & avkastning (bygger på 01 §5 og §4.1)

* **Holdinger:** brukeren bygger porteføljen over tid ved å bla i et anonymisert, etterslept univers (§9 «browse/similar») og kjøpe. Hver posisjon har retning (long/short), vekt og `opened_at` (i `game_now`). Cash er residualen. Vekting justeres løpende (samme sleeve-modell som Manager, **01 §4.1**: long-sleeve `w·G`, short-sleeve `max(0, w(2−G−bΔt))` med den asymmetriske utslettelsen, cash-sleeve `w·(1+R_f)`).
* **NAV (tidsvektet):** ingen eksterne kontantstrømmer ⇒ tidsvektet avkastning er ren daglig lenking av NAV (01 §5). NAV beregnes **EOD** fra de etterslepte, normaliserte kursene; lagres daglig (`rt_nav_daily`) for graf og scoring.
* **Benchmark:** S&P 500 TR (SPY-proxy, 03 S5.1), **etterslept samme Δ** så alpha er apples-to-apples. US-only i v1 (konsistent med blindspillet og benchmarket; OBX/globalt er §13).
* **30-dagers karantene:** etter salg av et selskap er det utestengt fra brukerens nye kjøp i 30 dager (`game_now`-tid). Hindrer bias-drevet kjøp/salg-looping (Instructions §2C). Håndheves i API/porteføljelaget, **ikke** i scoringmotoren (01 §5).

---

## 5. Scoring (fra 01 §5)

* **Porteføljescore = rullerende IR mot indeks**, over **90d og 365d**-vinduer, samme tanh-avbildning som ellers (`100·tanh(IR/IR_τ)`). Det korte vinduet vises alltid med **«lav signifikans»-merke** (01 §5: 90-dagers IR er mest støy). Ingen score på totalavkastning – det ville belønne beta/flaks.
* **Earnings-poeng (se §6):** binær `+10 / −5` (config) i v1; **Brier-basert** i v1.1.
* **Sesonger (forslag, §13):** for sosial/kompetitiv kadens uten å presse churn, foreslås **kvartalsvise sesonger** (matcher earnings-rytmen og det langsiktige etoset) med rullerende IR vist kontinuerlig. Leaderboard er sekundært (Instructions §2C).
* **Karantene utenfor scoring** (01 §5): karantenen former *hva du kan kjøpe*, ikke poengene.

---

## 6. Earnings-prediksjon & kalibrering (kjernen, sammen med porteføljen)

*Din beslutning: begge integrert; binær v1 → Brier v1.1.*

**Loop per event:**
1. **Event-deteksjon:** et selskap du holder «rapporterer» i `game_now` (dvs. dets faktiske rapport for kvartalet som faller innenfor bufferen). Du varsles før (anonymisert: «en av posisjonene dine rapporterer snart»).
2. **Prediksjon med obligatorisk begrunnelses-tag:** du spår **over/under** (v1 binær) med én tag ∈ {`margin`, `vekst`, `makro`, `verdsettelse`, `sentiment`} (Instructions §2C). Tvinger artikulering av tesen *og* gir gull-data: «brukere som begrunner med marginer treffer X % av tiden».
3. **Scoring mot kjent fasit:** fordi rapporten ligger innenfor etterslepet, er det faktiske utfallet *kjent for systemet* → umiddelbar, deterministisk scoring (`+10/−5`). Ingen venting, ingen live-estimatfeed.
4. **Reveal uten navn:** utfallet vises anonymisert («slo konsensus-EPS med 5 %, omsetning +12 % å/å, margin +180 bps»). Selskapet forblir skjult til salg (§3.6).

**«Beat/miss» mot hva (data-avhengighet jeg flagget):**
* Foretrukket: **mot analytiker-konsensus** (markedsrelevante «surprise»). Krever *historisk* konsensus for det etterslepte kvartalet — **må verifiseres på FMP** (sannsynlig kilde: `earnings-surprises`/estimat-endepunkter med `eps` vs `epsEstimated`; jf. probe-metoden i `fmp_api_questions.md`). **Fallback uten konsensus:** retning/akselerasjon **mot samme kvartal i fjor (YoY)** — alltid tilgjengelig fra `financials`, ingen estimat-avhengighet. (§13.)

**v1.1 – Brier-score (kalibrering):** brukeren oppgir en **sannsynlighet** (%) for «beat» i stedet for binært. Scores med Brier `(p − utfall)²` aggregert til en kalibreringskurve i «Din investorprofil». Dette er den pedagogisk sterkeste delen – kalibrert sannsynlighetstenkning er kjernen i god prognose. Begrunnelses-tags beholdes i begge versjoner (gull-dataen er uavhengig av scoringsformen).

---

## 7. Datamodell (delta mot 02)

02s tabeller dekker batch-spillet; Real-Time trenger egne portefølje-/prediksjons-tabeller. Truth holdes **service-only** til salg-reveal (samme grense som 02 §10).

```sql
-- Levende posisjoner (truth: company_id/navn ikke klient-lesbar før salg)
create table rt_holdings (
  id          bigint generated always as identity primary key,
  user_id     uuid   not null references profiles(id) on delete cascade,
  company_id  bigint not null references companies(id),     -- TRUTH (service-only)
  direction   text   not null check (direction in ('long','short')),
  weight      numeric not null,
  opened_at   date   not null,                              -- i game_now
  closed_at   date,                                         -- null = åpen
  entry_payload jsonb not null,                             -- frosset anonymisert kort ved kjøp
  reveal_name text                                          -- settes først ved salg
);
alter table rt_holdings enable row level security;          -- ingen klient-policy: service-only

-- Daglig NAV (normalisert), for graf + IR-scoring
create table rt_nav_daily (
  user_id uuid not null references profiles(id) on delete cascade,
  date    date not null,                                    -- game_now-dato
  nav     numeric not null,                                 -- rebasert (start = 1.0)
  primary key (user_id, date)
);

-- Earnings-prediksjoner (gull-dataen + kalibrering)
create table rt_predictions (
  id           bigint generated always as identity primary key,
  user_id      uuid   not null references profiles(id) on delete cascade,
  holding_id   bigint references rt_holdings(id) on delete set null,
  company_id   bigint not null references companies(id),    -- TRUTH (service-only)
  period_date  date   not null,                             -- kvartalet det spås om
  prediction   text   check (prediction in ('beat','miss')),-- v1 binær
  probability  numeric,                                     -- v1.1 (Brier)
  rationale_tag text  not null
                check (rationale_tag in ('margin','vekst','makro','verdsettelse','sentiment')),
  actual       text,                                        -- kjent (etterslep) -> deterministisk
  correct      boolean,
  brier        numeric,                                     -- v1.1
  created_at   timestamptz default now(),
  unique (user_id, company_id, period_date)
);
alter table rt_predictions enable row level security;
create policy own_predictions on rt_predictions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

* **Karantene** derives fra `rt_holdings.closed_at + 30 dager` (ingen egen tabell nødvendig).
* **Truth-grensen:** `rt_holdings.company_id`/`reveal_name` og `rt_predictions.company_id` er service-only (RLS på, ingen policy) – akkurat som `batch_cards` (02 §10). FastAPI serverer anonymisert payload; navn returneres *kun* i salg-reveal-svaret.
* **Analytics:** `rt_predictions` er både produktfeature (kalibrering) og forskningsdataene om tankefeil (Instructions §2/§8) – `rationale_tag` ⋈ `correct` gir «margin-prediktorer treffer X %».

---

## 8. Pipeline (delta mot 03)

* **Etterslept løpende ingest:** samme stadier som 03 (S2 entiteter, S3 point-in-time finans, S4 kurser, S5 benchmark/rf, S6 makro), men målt opp til `game_now = real_now − Δ`, og kjørt **inkrementelt daglig** (klokken glir framover).
* **Gjenbruker** anonymisering + leak-sjekk (S7) + normalisering – ingen ny maskineri. Forskjellen fra blind-batchene: i stedet for å sele faste 5-kort-batcher, genererer pipelinen en **løpende strøm av anonymiserte kandidat-kort** (etterslept univers) brukeren kan kjøpe, og **earnings-event-payloads** per holdt selskap når dets rapport faller innenfor bufferen.
* **Univers:** etterslept S&P 500 (US-only v1). OBX/globalt krever benchmark/valuta-håndtering (§13).
* **Earnings-fasit:** hentes fra `financials` (kjent innenfor etterslepet) + ev. `earnings-surprises` for konsensus (§6, må verifiseres).

---

## 9. API (utvider 05)

Truth eksponeres **aldri** før salg. Alle ruter krever JWT.

* `GET /v1/rt/browse?category=&similar_to=` – anonymiserte kandidat-kort (etterslept univers) å kjøpe fra.
* `POST /v1/rt/holdings` / `PATCH /v1/rt/holdings/{id}` / `POST /v1/rt/holdings/{id}/sell` – kjøp/juster/selg. **Salg returnerer reveal** (navn + full historikk for posisjonen) og starter 30-dagers karantene.
* `GET /v1/rt/portfolio` – posisjoner (anonymisert), rebasert NAV-serie vs indeks, rullerende IR (90d/365d) med signifikans-merke.
* `GET /v1/rt/events` – kommende/aktuelle earnings-events for dine hold (anonymisert).
* `POST /v1/rt/predictions` – send prediksjon (binær v1 / sannsynlighet v1.1) + obligatorisk `rationale_tag`. Svar inkluderer scoret utfall (anonymisert).
* `GET /v1/rt/calibration` – din kalibreringsprofil (v1.1 Brier + tag-treffrater).
* **Varsler:** push før et holds rapport (anonymisert «en posisjon rapporterer snart»).

Caching: alt er per-bruker (portefølje, prediksjoner, reveal) → **ikke** cachebart, i motsetning til Dagens Rundes felles kort.

---

## 10. Frontend (utvider 06)

Gjenbruker kort/swipe-rammen og det rolige temaet (06 §1, §14). Nye skjermer:

* `RtPortfolioScreen` – **rebasert** NAV-graf (din portefølje vs indeks; aldri kroner/absolutt nivå), rullerende IR med «lav signifikans»-merke på 90d, posisjonsliste (anonymisert).
* `RtBrowseScreen` – bla i anonymiserte kandidater, «similar companies», kjøp.
* `RtHoldingCard` – anonymisert posisjonskort (bånd-makro, indekserte tall, normalisert kursutvikling siden kjøp).
* `RtEarningsPredictionFlow` – varsel → spå over/under (v1) / sannsynlighet (v1.1) → **obligatorisk begrunnelses-tag** → anonymisert utfall-reveal.
* `RtSellReveal` – navn + full historikk avsløres *kun her*; karantene-indikator.
* `RtCalibrationScreen` (v1.1) – Brier-kurve + tag-treffrater i «Din investorprofil».
* **Estetikk:** ekstra rolig – ingen rød/grønn tick-jakt, EOD-oppdatering, langsiktig framing (06 §1). Earnings-varsler er nøkterne, ikke alarmer.

---

## 11. Guardrails & anti-gaming

* **Virtuelle penger; «ikke investeringsråd»-disclaimer** tydelig (Instructions §2C). Spesielt viktig for earnings-prediksjonene, som ellers kan ligne betting i App Store-review (Instructions §8).
* **Churn-motstand bygget inn:** (a) 30-dagers karantene; (b) IR-ikke-totalavkastning fjerner insentiv for å jage volatilitet; (c) EOD-NAV (ingen intradag) fjerner tick-jakt; (d) etterslep-bufferen gjør «nyhetsscalping» umulig. Designet motvirker det day-trading-mønsteret modusen ellers kunne invitert til.
* **Leaderboard sekundært:** sesonger/ligaer er sosialt krydder, ikke kjernen (indeks + læring er det).

---

## 12. Grensesnitt mot nabo-specs

* **← 01_scoring:** §5 er kontrakten – rullerende IR (90d/365d) + tanh + lav-signifikans-merke; earnings `+10/−5` (v1) → Brier (v1.1); karantene utenfor scoring. Sleeve-modellen (§4.1) gjenbrukes for NAV.
* **← 02_datamodell:** nye `rt_holdings`/`rt_nav_daily`/`rt_predictions`; truth service-only (samme RLS-grense som `batch_cards`, §10).
* **← 03/04:** gjenbruker point-in-time, anonymisering, leak-sjekk (03 §7.2), epoke-anonymitet (04 §5.7) – kjørt løpende på etterslept klokke.
* **← 05_api:** nye `/v1/rt/*`-ruter; truth kun i salg-reveal.
* **← 06_frontend:** gjenbruker kort/swipe/tema; nye RT-skjermer.
* **← 07_kartoteket:** distinkt (Kartoteket = nåtid/ekte/navngitt; Real-Time = etterslept/normalisert/anonymt). «Hva har skjedd siden sist»-resirkulering i Kartoteket (07 §6.2) er en naturlig bro hit.

## 13. Åpne beslutninger

1. **Etterslepets størrelse `Δ`:** nøyaktig ett kvartal, eller justerbart (f.eks. 1 mnd for «ferskere» følelse vs lengre for sikrere anonymitet)? Forslag: ett kvartal (én earnings-syklus); config.
2. **Konsensus-estimat-fasit (verifiseringspunkt):** har FMP *historisk* konsensus (`earnings-surprises`/estimater med `epsEstimated`) på Premium? Hvis ja → «beat/miss vs konsensus». Hvis nei → fallback YoY-retning. Probe før §6 bygges.
3. **Sesong-kadens** (§5): kvartalsvise sesonger, månedlige, eller kun kontinuerlig personlig IR? Forslag: kvartalsvise sesonger + kontinuerlig rullerende IR.
4. **Univers:** US-only v1 (matcher benchmark). OBX/globalt krever etterslept lokal TR-indeks + valuta – utsett til §07s OBX-dekning er bekreftet og blindspillet er multivaluta.
5. **Ekte sanntid noen gang?** v1/v1.1 er bevisst etterslept (tractable, anonymt, deterministisk). Et ekte-sanntids-spor (live estimater, vente-på-rapport-scoring) er en separat, mye dyrere utvidelse – sannsynligvis aldri, gitt det langsiktige etoset.
6. **Oppdagelse/kurasjon av kandidater** (§9 browse): helt fri bla i hele etterslepte universet, eller kuratert/anbefalt strøm (sektorer, «similar») for å unngå valgparalyse? Forslag: kategorier + «similar», ikke en flat liste på tusenvis.
7. **Vektingsmodell ved kjøp:** fri vekt per posisjon (med caps som Manager, 01 §4.1) eller forhåndsdefinerte porsjoner? Forslag: fri vekt med samme sanity-caps som Manager.
8. **Varselkadens:** hvor ofte/hvor nær rapport varsles det? Bør være nøkternt (én rolig varsel), ikke push-spam (06 §1-etos).