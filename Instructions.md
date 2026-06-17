# Instructions.md – Project: KAP

## 1. Prosjektoversikt

**KAP** (arbeidstittel, tidl. "Blind Monkeys") er en gamifisert finansapplikasjon designet for å lære brukere fundamental analyse ved å fjerne bias knyttet til selskapsnavn, ticker og hype.

**Kjernekonsept:** Brukeren presenteres for anonymiserte "selskaps-kort" som inneholder nøkkeltall, bransje og makroøkonomisk kontekst fra en historisk periode. Brukeren tar aktive valg (Long, Short, Cash) basert på dataene alene og konkurrerer om alpha mot indeksen. I tillegg kommer **Kartoteket** – et ikke-anonymisert, swipebart bibliotek over børsnoterte selskaper som bygger bredde og dybde i selskapskunnskap.

**Posisjonering (one-liner):** *«GeoGuessr for fundamental analyse»* – du får regnskapet, makrobildet og narrativet, men ikke navnet. Klarer du å skille vinnere fra tapere når hypen er strippet vekk?

**Fire moduser:**
1. **Junior Mode** – rask blindrunde (arcade, 5 kort)
2. **Manager Mode** – lengre blindrunde med porteføljevekting
3. **Real-Time Mode** – løpende anonymisert portefølje på sanntidsdata
4. **Kartoteket** – utforskningsmodus med ekte navn (NY)

I tillegg: **Dagens Runde** – én global, synkronisert Junior-batch per dag (growth-motoren).

### Målsetning

* Lære brukere å lese regnskapstall uten hindsight bias og merkevarebias. Læring i alle ledd: fagbegrep skal kunne ekspanderes for definisjoner, og brukeren kan sette eget kunnskapsnivå (nybegynner får mer inngående definisjoner, eksperten slipper noobfakta).
* Innsikt i fundamental analyse, makrobilde, nøkkeltallanalyse og finansregnskap som beslutningsgrunnlag på mellomlang sikt.
* Tilby en morsom, rask måte å teste investeringsstrategier på – motsatsen til teknisk analyse og umiddelbar dopamin. Tailored for Warren Buffett-skolen, ikke daytrading.
* Bygge **bredde**: de fleste retail-investorer kjenner ~20 selskaper. Kartoteket skal gjøre at brukeren passivt og aktivt blir kjent med hundrevis – med mulighet for dybdeanalyse per selskap.
* Skape en bro mellom teori og praksis gjennom historiske simuleringer og sanntids blindtester.

---

## 2. Spillmoduser (Core Mechanics)

### A. Junior Mode (Arcade)

* **Format:** En rask runde med 5 kort i tinderformat.
* **Data:** 5 selskaper fra samme historiske beslutningsdato (f.eks. tall tilgjengelig per Q1 2019), på tvers av sektorer. Resultatet er total­avkastningen over de neste 3–5 årene (f.eks. Q1 2019 → Q1 2024).
* **Valgmuligheter:**
  1. **Long (Swipe Høyre):** Du tror aksjen blir en god investering.
  2. **Short (Swipe Venstre):** Du tror aksjen vil falle eller underprestere kraftig.
  3. **Cash (Swipe Opp/Skip):** Du står over. Gir risikofri rente fra perioden (hentet fra faktiske rentesatser – også avgjørende makroinfo).

* **Scoring (VIKTIG ENDRING – alt måles som alpha mot indeks):**
  * Long: `score = r_aksje − r_indeks`
  * Short: `score = −(r_aksje − r_indeks)`
  * Cash: `score = r_f − r_indeks`
  * **Hvorfor:** Spillere optimaliserer poengfunksjonen, ikke intensjonen bak den. Med absolutt avkastning er «Long alt» dominant strategi i enhver bullperiode, og spillet lærer bort beta-jakt – det stikk motsatte av tesen. Alpha-scoring belønner *seleksjon*. Merk at cash i et bullmarked da gir negativ score – som er korrekt lærdom.
  * Pedagogisk note i reveal: ekte shorting er asymmetrisk (lånekostnad, ubegrenset nedside, markedet drifter opp). Junior holder det symmetrisk for enkelhet; Manager Mode kan modellere asymmetrien.

* **Algoritmen (The Curator):** Utvalget på 5 kort er ikke tilfeldig. Constraints:
  * Alle kort fra samme beslutningsdato (slik at ett makrobilde gjelder hele bunken).
  * Minst én vinner (≥ **+10 %-poeng årlig alpha** mot indeks) og én taper (≤ **−10 %-poeng årlig alpha**). Terskelen er en config-parameter: stram i starten gir tydelige læringssignaler; kan strammes inn som difficulty-mekanikk senere. (Original-terskelen på ±3 % over 3–5 år er for nær støy til å garantere en «løsning».)
  * Maks 2 kort fra samme sektor, blandede cap-kategorier.
  * Deterministisk via seed (muliggjør Dagens Runde og reproduserbarhet).

* **The Reveal:** Etter 5 valg avsløres selskapsnavnene, faktisk kursutvikling (totalavkastning), brukerens alpha mot indeks, idealporteføljen, og én clue-setning per kort om hva som var signalet («Selskap X: høy gearing inn i renteøkning»). Hvert avslørt selskap har CTA: **«Legg til i Kartoteket»** → mater utforskningsmodusen.

### B. Manager Mode (The Main)

* **Format:** Lengre og mer intrikat runde, **25–30 kort** (50 er trolig for lang sesjon for en mobilapp – test, men start lavere eller del i kapitler). Tinderformat som Junior.
* **Vekting (UX-endring):** Høyre-swipe markerer Long *uten* vektingsdialog underveis – dialog per swipe bryter flyten som gjør formatet vanedannende. I stedet: alle valgte selskaper får default likevekt, og vektingen justeres på **«Bekreft portefølje»-skjermen** til slutt, i tråd med porteføljeteori. Ikke krav om 100 % i aksjer; resten settes i cash.
* **Data:** Større univers enn Junior – selskaper fra hele verden, flere og lengre tidsperioder. Det velges 8–12 selskaper.
* **Scoring:** Alpha mot indeks, **risikojustert**: juster sluttscore etter realisert Sharpe (eller Sortino) for porteføljen over perioden, slik at man ikke vinner på flaks med ett volatilt vekstselskap. Realisert volatilitet beregnes fra de daglige kursene som allerede ligger i DB.
* **Short-modellering (valgfritt, mer realistisk enn Junior):** cap gevinst på +100 %, ev. trekk en stilisert lånekostnad. Læringspoeng: short er ikke speilbildet av long.

### C. Real-Time Mode (The Companion)

* **Format:** Løpende portefølje basert på dagens marked, anonymisert, i samme kortformat. Mulighet for å browse kategorier og «similar companies», og redigere portefølje/vekting fortløpende. Lagt opp til langsiktige valg – skal motivere Warren Buffetter, ikke multi-screen TikTok-guruer.
* **Events:** Fokus på earnings calls. Brukeren varsles før tall slippes og predikerer over/under forventning – **med obligatorisk begrunnelses-tag** (margin / vekst / makro / verdsettelse / sentiment). Tvinger artikulering av hypotesen *og* gir gull-data: «brukere som begrunner med marginer treffer X % av tiden».
* **Reveal:** Navn avsløres først ved salg; deretter 30 dagers karantene på samme selskap for å hindre bias-drevet kjøp/salg-looping. (Behold – smart mekanikk.)
* **Guardrails:** Kun virtuelle penger. Tydelig «ikke investeringsråd»-disclaimer. Resultatlister mot venner er sekundært; indeksen og læring er hovedfokus.
* **Scope-gate:** Dette er i praksis en egen app (live-data, varsler, porteføljeforvaltning, anti-gaming). Bygges sist, og kun når Junior + Kartoteket har bevist retention.

### D. Kartoteket (Explore Mode) — NY

* **Konsept:** Ikke-anonymisert, swipebart bibliotek over børsnoterte selskaper. Quartr-inspirert i innhold, GeoGuessr/Pokédex i form. Mål: bredde (kjenne mange selskaper overfladisk) med fri vei til dybde (full profil per selskap).

* **Decks:** Kuraterte bunker man swiper gjennom: «S&P 500 Tech», «OBX», «Utbytte-aristokrater», «ROIC > 15 % i 10 år», «Nye på børs siste 2 år», «2008-overleverne». Decks kan være håndkuraterte eller screen-genererte (samme pipeline som spillmodusene). I tillegg: **«Dagens selskap»** – ett kort om dagen, lav terskel.

* **Kortanatomi (lagvis, tap for å utvide – progressive disclosure):**
  0. *Front:* Navn, ticker, sektor, énsetnings forretningsmodell i klarspråk (AI-generert), 3–4 hero-nøkkeltall, sparkline.
  1. *Forretning:* Segmenter, inntektsmiks, konkurransefortrinn/moat.
  2. *Historikk:* 10 år med omsetning/EPS/marginer/FCF (fl_chart).
  3. *Verdsettelse:* Multipler vs egen historikk og vs peers.
  4. *Siste kvartal:* AI-sammendrag av earnings call (Quartr-light).
  5. *Bull/Bear:* To setninger hver – trener tosidig tenkning.

* **Swipe-semantikk (gjenbruker muskelminnet fra spillmodusene):**
  * Høyre = lagre i **Min samling** (watchlist)
  * Venstre = neste kort
  * Opp = deep-dive (åpner full profil)
  * Langt trykk = gjettemodus (se under)

* **Samlingsmekanikk (Pokédex-effekten):** Dekningsmetere per indeks/sektor: «Du kjenner nå 38 % av OBX», badges per sektor fullført. Gamifiserer bredde-målet direkte. Lagrede selskaper resirkuleres når nye kvartalstall kommer («hva har skjedd siden sist») – naturlig bro inn i Real-Time Mode senere.

* **Gjettemodus (aktiv læring):** Skjul ett nøkkeltall på kortet og la brukeren gjette intervall før avsløring («P/E over eller under 20?»). Gjør passiv lesing om til retrieval practice – det er gjenhenting, ikke gjenlesing, som bygger varig kunnskap.

* **Kobling til blindmodusene (loopen som binder appen sammen):**
  1. Reveal-skjermen i Junior/Manager har «Legg til i Kartoteket»-CTA.
  2. Selskaper i samlingen viser din blindhistorikk: «Du shortet dette i en 2019-runde – det steg 212 %.» Førsteinntrykk uten bias → fasit → varig kjennskap.
  3. Curator kan nedvekte selskaper brukeren nylig har utforsket i Kartoteket (leaderboard-integritet), eller flagge dem som «kjent» i scoringen.

* **Hvorfor modusen styrker, ikke kannibaliserer, blindspillet:** Anonymiteten hviler på universstørrelsen (tusenvis av selskap × periode-kombinasjoner), ikke på at brukeren er uvitende. At man gjenkjenner et selskap man har studert, er læring – ikke juks. Og Kartoteket gir appen en grunn til å åpnes *mellom* spillsesjoner: spillmodusene er sesjoner, Kartoteket er innhold. Det adresserer retention-gapet og er en bredere acquisition-kanal («jeg vil lære om selskaper» er et større marked enn «jeg vil spille et finansspill»).

* **Datapipeline:** Gjenbruker hele pipelinen fra blindmodusene minus anonymisering. Tillegg: forretningsbeskrivelse i klarspråk + earnings-sammendrag (begge AI-batch-genererte og cachet, ikke runtime).

### E. Dagens Runde (growth-motoren)

* Alle brukere globalt får **samme 5 kort hver dag** (seedet Curator-batch, én per dato).
* **Streak**-mekanikk + delbart resultat: emoji-grid (🟩 riktig retning / 🟥 feil / ⬜ cash) pluss alpha mot indeks – uten å spoile hvilke selskaper det var.
* **Hvorfor (Wordle-prinsippet):** Synkronisert innhold skaper et sosialt objekt – alle kan diskutere «kort 3 i dag» uten spoilere, og delingen er organisk distribusjon. Bonus: én håndpolert batch per dag er overkommelig å kvalitetssikre, i motsetning til uendelige tilfeldige batches.
* MVP-en bygges rundt denne, ikke rundt fri spilling.

---

## 3. Datastruktur & Visning (The Card)

Hvert blindkort inneholder tre informasjonslag som simulerer en ekte investors beslutningsgrunnlag:

1. **Makro-boksen (Kontekst):**
   * Beskriver det økonomiske klimaet uten å nevne årstall.
   * *Variabler:* Rentenivå/retning (Høy/Lav/Økende/Fallende), inflasjon og BNP-vekst **som kvalitative bånd** (ikke presise tall – et presist inflasjonstall fingeravtrykker epoken), sektorsentiment.
   * *Merk (epoke-anonymitet):* Spilleren **skal** kunne lese regimet og resonnere om det (økende renter → skepsis til gjeld og høye multipler) – det er en kjerneferdighet. Hun skal **ikke** kunne pinne kalenderåret og anvende fasit (epoke + sektor → «short tech i 1999»). Derfor: grovkornet makro (bånd, ingen tall, ingen årstall) gir nok til regime-resonnement, men ikke nok til å tidfeste året. Det beskyttede er *selskapsidentitet* **og** *kalenderepoke* – ikke regimet selv.

2. **Fundamentale Tall (Hard Data):**
   * Verdsettelse (P/E, P/S, ev. EV/EBIT).
   * Kvalitet (Gjeld/EK, marginer, ROIC).
   * Vekst (3 års CAGR på revenue/EPS).
   * Kategori (Small/Mid/Large Cap).

3. **Narrativ (Soft Data – AI-generert):**
   * 2 setninger som oppsummerer situasjonen basert på nyhetsbildet fra perioden, strippet for produkt- og firmanavn.

4. **Introkort (Periodekontekst):** Kjappe fakta før runden starter – markedssentiment (fear/greed-aktig), rentebilde, hva slags marked man går inn i. Setter rammen for alle 5 kort.

### Anonymiseringsregler

* **Aldri absolutte beløp.** Omsetning vises som indeksert serie (100 → 134 → 161) + CAGR, ikke i dollar. Market cap kun som kategori. (Absolutt størrelse avslører gigantene umiddelbart.)
* Nøkkeltallene selv holdes presise – de *er* læringsobjektet. Anonymisering skjer via fravær av navn/beløp/produkter, globalt univers og mange tidsvinduer.
* Sektor vises på overordnet nivå der industrinivå er avslørende (f.eks. «Teknologi – hardware», ikke «smarttelefoner»).
* Aksepter at eksperter av og til gjenkjenner ikoniske selskaper. Dagens Runde-kuratoren kan ekskludere de ~50 mest gjenkjennelige selskapene fra blindbunkene.
* **Leak-sjekk på narrativ** (selskapsidentitet) er et eget pipeline-steg (se §5).
* **Epoke-lekkasjesjekk på makro-/sentiment-tekst** (parallelt til selskaps-leak-sjekken): makro-setningen og sektorsentimentet må ikke navngi epokedefinerende hendelser (pandemi, finanskrise, dot-com, Lehman, krig) eller andre årstalls-fingeravtrykk. Samme to-trinns mønster som §5 (regex + LLM-dommer: «kan du tidfeste dette til ±2 år?» → regenerér ved treff). Inflasjon/BNP-vekst vises som kvalitative bånd, ikke tall.

---

## 4. Dataintegritet (KRITISK – les før pipeline bygges)

Spillet er i praksis **en backtest med UI**. Det betyr at alle klassiske backtest-feller gjelder, og hver av dem ville ikke bare gitt feil tall – de ville lært brukerne *gale lekser*:

1. **Survivorship bias:** Hvis universet bygges fra *dagens* S&P 500-liste og man viser 2019-tall, finnes bare overleverne i datasettet. Da blir Long systematisk riktigere enn det var i virkeligheten, og spillet underviser i overdreven optimisme. **Løsning:** Bygg universet for beslutningsdato T fra *historiske indekskonstituenter per T* + delistede selskaper. FMP `stable` har endepunktene (`historical-sp500-constituent`, `delisted-companies`); delistede *kurser* krever Premium (verifisert via probe). Eksakt endepunktliste i 05 §7–§8.
2. **Look-ahead bias:** Q1 2019-regnskapet var ikke kjent 1. april 2019 – det ble rapportert uker senere. Kortet må vise *sist rapporterte tall per beslutningsdato*, keyet på **filing date**, ikke periodedato. Startkursen for avkastningsberegningen settes til første handelsdag *etter* at informasjonen på kortet var offentlig.
3. **Totalavkastning, ikke kursavkastning:** Bruk justerte kurser (utbytte reinvestert) og en total return-indeks som benchmark. Ellers ser utbytteselskaper – selve Buffett-segmentet – systematisk dårligere ut enn de var. Det ville undergravd appens egen tese.
4. **Splitt-/datavask:** Filtrer manglende verdier og unormale hopp som skyldes splittfeil (originalplanens punkt 10 – hører hjemme her).
5. **Valuta og benchmark:** MVP avgrenses til USA: USD, S&P 500 Total Return som benchmark. Globalt univers (Manager Mode) krever lokal indeks/valuta-håndtering – utsett kompleksiteten.

*Generaliserbart prinsipp:* Dette er identisk med backtest-hygiene i kvantfinans. Sjekklisten «survivorship, look-ahead, total return, transaksjonsrealisme» bør kjøres på enhver historisk finanssimulering – også utenfor dette prosjektet.

---

## 5. Teknisk Stack & Arkitektur

### Backend (Data & Logic)

* **Språk:** Python, nyeste versjon.
* **Rammeverk:** FastAPI (REST API).
* **Databehandling kontinuerlig:** Pandas & NumPy.
* **Databehandling engangs/batch:** En lett LLM (OpenAI API el.l.) for narrativer, makro-setninger, resultatforklaringer, forretningsbeskrivelser (Kartoteket) og earnings-sammendrag. Kjøres batch-vis (kvartalsvis / ved innholdsutvidelse) og caches i DB – **aldri runtime per bruker** (kost + kvalitetskontroll).
* **Datakilder:** Financial Modeling Prep (FMP) API (`stable`). Krav: statements m/ filing dates, *utbyttejusterte* kurser (`historical-price-eod/dividend-adjusted`), historiske indekskonstituenter, delistede selskaper. Makro + risikofri (renter, inflasjon, BNP): FMP `treasury-rates` + `economic-indicators`; FRED kun fallback. Full endepunktliste i 05 §7–§9.

### Database

* **System:** PostgreSQL.
* **Hosting:** Anbefalt: **Supabase fra dag 1** (Postgres + Auth + RLS i én pakke, kjent fra Plugga-prosjektet) – fjerner Docker-friksjon og løser brukerhåndtering gratis. Lokal Docker-container beholdes som alternativ for offline-utvikling. FastAPI beholdes uansett for spill-logikken; Supabase brukes som DB + auth, ikke som backend.
* **Analytics fra dag 1:** Hver beslutning logges med kort-features (se datamodell). Dette er både produktanalyse, grunnlaget for «Din investorprofil»-featuren (backlog), og forskningsdata om vanlige tankefeller. Skal bli store data – grunnlaget legges nå.

### Datamodell (skisse)

* `companies` (ticker, navn, sektor, industri, land, valuta, is_delisted)
* `financials` (ticker, period_date, **filing_date**, revenue, net_income, eps, pe, ps, debt_to_equity, marginer, roic, …)
* `prices` (ticker, dato, adj_close)  — justert for splitt *og* utbytte
* `index_prices` (indeks, dato, tr_close)
* `macro_context` (dato, region, rente_nivå, rente_retning, inflasjon, bnp_vekst, ai_setning)
* `narratives` (ticker, decision_date, narrativ, sektorsentiment, clue_setning, resultatforklaring, leak_check_passed)
* `game_batches` (id, mode, decision_date, horizon_years, seed, is_daily, daily_date)
* `batch_cards` (batch_id, card_no, ticker)
* `users` (id, created_at, auth_type, knowledge_level)  — anonym/device-basert først, konto valgfritt
* `decisions` (user_id, batch_id, card_no, choice, weight, response_ms, created_at)
* `collections` (user_id, ticker, saved_at, source)  — Kartoteket
* (Originalens `market_data` er splittet: kurser, indeks og forklaringstekster er separate concerns.)

### Frontend (Mobile App)

* **Rammeverk:** Flutter (Dart). *(Åpent spørsmål: React Native/Expo ville gjenbrukt eksisterende React-kompetanse og gitt raskere MVP; Flutter gir bedre animasjons-/swipe-følelse og er et bevisst læringsvalg. Avgjør før Fase 4 – se Backlog.)*
* **State Management:** Riverpod.
* **Nøkkel-biblioteker:** `flutter_card_swiper`, `fl_chart`, `dio`.

---

## 6. MVP-definisjon

> **MVP = Dagens Runde.** Junior Mode med USA-univers, 2–3 historiske periode-pooler, alpha-scoring, reveal med clue-setninger, delbart resultat-grid, streak, anonym auth. *Ingenting annet.*

Begrunnelse: Én polert loop slår fire halvferdige moduser. Manager, Real-Time og full Kartotek er fase-gatet bak bevist retention på kjerneloopen. Kartoteket får likevel et «frø» i MVP: en enkel selskapsside som reveal-skjermen lenker til.

---

## 7. Steg-for-Steg Implementasjonsplan

### Fase 1: Miljø, Database og Fundament

1. **Repo Setup:** GitHub-repo, `.gitignore` for Python + Flutter, `venv`.
2. **API-tilgang:** FMP-konto + nøkkel i `.env` (ikke i git). **Verifiser at tieret gir historical constituents, delisted companies og filing dates** før du bygger videre.
3. **Database:** Opprett Supabase-prosjekt (alt.: lokal Docker-Postgres). Sett opp migrasjonsverktøy (f.eks. Alembic eller Supabase migrations).
4. **Skjema – selskaper og finans:** `companies`, `financials` (med filing_date).
5. **Skjema – kurser:** `prices` (adj_close), `index_prices` (total return).
6. **Skjema – innhold:** `macro_context`, `narratives`.
7. **Skjema – spill & analytics:** `users`, `game_batches`, `batch_cards`, `decisions`, `collections`. Analytics-grunnlaget legges her, dag 1.

### Fase 2: Backend Data Pipeline (Python)

8. **Universbygger:** Hent historiske S&P 500-konstituenter per dato + delistede selskaper → funksjon `universe(decision_date)` som returnerer det som faktisk var investerbart da. (Survivorship-fiksen.)
9. **Statements-fetcher:** Income statement + balance sheet (+ ratios) siste 10 år for universet, lagret med filing_date.
10. **Pris-fetcher:** Daglige *justerte* sluttkurser for aksjer + S&P 500 TR.
11. **Avkastningsmotor:** `total_return(ticker, start, horizon)` og `alpha(ticker, start, horizon)` – totalavkastning mot indeks. (Look-ahead-fiksen: start = første handelsdag etter siste filing_date på kortet.)
12. **Datavask:** Filtrer manglende verdier, splittfeil, ekstreme hopp. Karantenetabell for tvilsomme datapunkter.
13. **Makro-logikk:** Beregn makro-status per dato (rente-retning = sammenlign med året før, osv.), supplert med AI-generert kontekstsetning.
14. **AI-narrativ:** Script som tar nøkkeltall + dato → LLM → JSON med {narrativ, sektorsentiment, clue_setning, resultatforklaring}. Batch-kjøres og caches.
15. **Leak-sjekk (NY):** To-trinns kontroll av hvert narrativ: (a) regex/strengmatch mot selskapsnavn, ticker og kjente produktnavn; (b) LLM-dommer som får narrativet og spør «kan du identifisere selskapet?». Feilende narrativ regenereres automatisk.

### Fase 3: Spill-logikk (The Curator) & API

16. **Curator v1:** Velg 5 kort fra samme decision_date med constraints: ≥1 kort med årlig alpha ≥ +X %, ≥1 med ≤ −X % (X = config, start ~10), maks 2 per sektor, blandede cap-størrelser, ekskluder «for ikoniske» selskaper. Deterministisk via seed.
17. **Dagens Runde-jobb:** Cron som genererer én global batch per dag (seed = dato) → `game_batches(is_daily=true)`.
18. **FastAPI init.**
19. **Endepunkter – henting:** `GET /daily` og `GET /batch` → JSON med 5 anonymiserte kort (nøkkeltall + makro + narrativ + card_id). Ingen tickers i responsen.
20. **Endepunkt – innsending:** `POST /batch/{id}/submit` → tar valg per kort, returnerer score (alpha), faktiske navn, kursutvikling, clue-setninger, idealportefølje. Logger alt i `decisions`.
21. **Endepunkt – selskap (lite):** `GET /company/{ticker}` → grunnlag for reveal-siden, og senere Kartotekets deep-dive.

**Videre:** Manager og Real-Time gjenbruker Curator/API med egne constraints når Junior-loopen er bevist.

### Fase 4: Frontend Oppsett (Flutter)

22. **Flutter Init:** `flutter create kap`, rydd boilerplate.
23. **Project Structure:** models, providers, screens, widgets, services.
24. **Models:** Dart-klasser som speiler API-et (`GameCard`, `GameResult`, `CompanyProfile`).
25. **API Client:** Dio mot FastAPI.

### Fase 5: UI & Spillmekanikk

26. **Card UI:** Fargekodet makro-boks, tydelig typografi for nøkkeltall, ekspanderbare fagbegrep (definisjoner etter kunnskapsnivå).
27. **Swipe-logikk:** `flutter_card_swiper`: Høyre = Long, Venstre = Short, Opp = Cash.
28. **Game Loop:** «Henter kort» → «Viser kort» → «Teller valg (0/5)» → «Sender svar».
29. **Resultatskjerm:** Score som alpha. Graf: «Din portefølje» vs «Indeks» (fl_chart).
30. **Reveal-animasjon:** Snu hvert kort: «Det var Tesla! Du valgte Short. −180 %-poeng alpha.» + clue-setning + knapp «Utforsk selskapet» (→ den lille selskapssiden fra steg 21).
31. **Delingskort (NY):** Generer delbart bilde/tekst: emoji-grid (🟩🟥⬜ per kort) + alpha + streak. Wordle-formatet, uten spoilere.
32. **Feedback & idealportefølje:** Tekstbasert tilbakemelding basert på alpha (oppmuntring/gratulasjon/terging) + den AI-genererte lærefeedbacken per kort.

### Fase 6: Polish & MVP Finish

33. **Onboarding-overlay:** Første gang: forklar makro-boksen, alpha-scoringen og cash-regelen. Inkluder kunnskapsnivå-velger (styrer definisjonsdybde).
34. **Lyd & haptikk:** Swipe-lyder (kaching/whoosh) + vibrasjon ved valg.
35. **Auth & streak:** Anonym/device-basert auth (Supabase), streak-teller, lokal notifikasjon «Dagens Runde er klar».
36. **Testing & Build:** E2E-gjennomgang, `.apk` + iOS-simulator. Soft launch til venner/NTNUI.

### Fase 7 (v1.1): Kartoteket

37. **Decks-motor:** Definer decks som lagrede screens/lister (sektor, indeks, tema). Gjenbruk eksisterende data.
38. **Samling & dekning:** `collections`-flyt, dekningsmetere per indeks/sektor, badges. «Dagens selskap»-kort.
39. **Deep-dive:** Utvid selskapssiden fra steg 21 til full lagvis profil (10-års grafer, peers, AI-earnings-sammendrag, bull/bear).
40. **Gjettemodus + blindhistorikk:** Skjul-og-gjett på nøkkeltall; vis brukerens tidligere blindvalg på selskapets side.

### Fase 8 (v1.2+): Utvidelser (gatet bak retention-data)

41. Manager Mode (vekting på bekreftelsesskjerm, Sharpe-justering).
42. **«Din investorprofil»:** Analyser `decisions` mot kort-features og vis brukerens systematiske skjevheter («Du longer lav P/E ukritisk – value trap-tendens», «Du straffer gjeld for hardt»). Retention-feature *og* forskningsdataene du ønsker om tankefeller – samme tabell, to formål.
43. Real-Time Mode.

---

## 8. Backlog & Åpne Spørsmål

* **Navn:** «Blind Monkeys» refererer til Malkiels pilkastende aper – som er argumentet for at aksjeplukking *ikke* virker. Appens tese er motsatt: seleksjon er en lærbar ferdighet. Navnet ville undergravd verdiløftet. KAP er sterkere (kapital/kapittel). Endelig navn avgjøres før App Store-innsending.
* **Flutter vs React Native/Expo:** Avveiing mellom læringsverdi (Flutter) og fart via eksisterende React-kompetanse (RN). Avgjøres før Fase 4.
* **Difficulty/ELO:** Curator får en vanskelighetsgrad (hvor «åpenbar» vinneren er, målt ved alpha-spredning); brukere rates, batches matches mot nivå.
* **Ligaer & venner:** Ukentlige ligaer på Dagens Runde (Duolingo-modellen).
* **Oslo Børs-univers:** Eget norsk univers (OBX/hovedlisten) – differensierende lokalt, og morsomt gitt eksisterende OSE-analyser.
* **Lokalisering:** Norsk + engelsk fra tidlig fase; innholdet er AI-generert og billig å oversette.
* **Monetisering (skisse):** Dagens Runde alltid gratis (vekstmotoren skal aldri bak paywall). Pro: ubegrensede runder, fullt Kartotek, Manager Mode, investorprofil.
* **App Store-hensyn:** Kategori Education/Finance. Kun virtuell valuta, ingen ekte penger, tydelige «ikke investeringsråd»-disclaimers – spesielt viktig for earnings-prediksjonene i Real-Time, som ellers kan ligne betting-mekanikk i review.

---

## Endringslogg (fra original)

1. **Ny modus D: Kartoteket** – ikke-anonymisert utforskningsmodus med samlingsmekanikk, decks, deep-dive og gjettemodus. Fase 7 i planen, med «frø» (selskapsside) allerede i MVP.
2. **Scoring endret til alpha mot indeks** i alle moduser (begrunnelse i §2A) + Curator-terskler flyttet fra absolutt ±3 % til årlig alpha ±10 %-poeng (parameterisert).
3. **Ny §4 Dataintegritet:** survivorship (historiske konstituenter + delistede), look-ahead (filing dates), totalavkastning, valuta/benchmark-avgrensning.
4. **Dagens Runde** lagt til som growth-motor og MVP-kjerne (Wordle-mekanikk, deling, streak).
5. **Manager Mode justert:** 25–30 kort i stedet for 50; vekting flyttet til bekreftelsesskjermen for å bevare swipe-flyt; eksplisitt Sharpe-justering.
6. **Real-Time Mode:** lagt til begrunnelses-tags på earnings-bets, guardrails og scope-gate.
7. **Leak-sjekk** av AI-narrativer som eget pipeline-steg.
8. **Datamodell utvidet** med users/decisions/collections m.m. (analytics og investorprofil fra dag 1); `market_data` splittet i separate tabeller.
9. **Supabase anbefalt fra dag 1** (DB + auth); Flutter vs RN flagget som åpen beslutning.
10. **MVP-definisjon** lagt til (§6) – kun Dagens Runde, alt annet fase-gatet.