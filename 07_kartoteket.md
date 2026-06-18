# 07_kartoteket.md – KAP Spesifikasjon: Kartoteket (utforskningsmodus)

> **Dokumentserie:** `01_scoring` ✓ · `02_datamodell` ✓ · `03_data_pipeline` ✓ · `04_curator` ✓ · `05_api` ✓ · `06_frontend_gameloop` ✓ · **`07_kartoteket` (dette)** · `08_realtime`
> Kartoteket er **v1.1** (Fase 7), men får et «frø» allerede i MVP (selskapssiden reveal lenker til, 05 §4.4 / 06 §10). Dette dokumentet spec'er den fulle modusen. Mye gjenbrukes fra 02 (`company_profiles`, `collections`, `decks`), 05 (endepunkter, segment/screener-funn) og 06 (swipe-rammen).

---

## 1. Designprinsipper

1. **Den bevisste motsatsen til blindspillet: nåtid, ekte tall, ekte navn.** Dette er ryggraden. Der blindkortet er *historisk, bånd-vist og anonymt*, er Kartotek-kortet *nåværende, absolutt og navngitt*. Brukeren ser «Equinor», ikke «et energiselskap»; «412 mrd NOK omsetning», ikke en indeksert serie; faktisk P/E nå, ikke point-in-time. Denne inversjonen forklarer nesten alle forenklingene under.
2. **Nåtids-naturen gjør datapaten enkel.** Fordi Kartoteket viser *dagens* selskap (ikke en beslutningsdato i fortiden) trenger det **ingen point-in-time-disiplin, ingen survivorship-rekonstruksjon, ingen leak-sjekk, ingen anonymisering** (03s tunge maskineri). Det leser siste tilgjengelige tall + historiske serier rått og ekte. FMPs `*-ttm`-/nåtids-endepunkter (05 §8.3, ubrukelige for blindspillet) hører nettopp hjemme her.
3. **Bredde med fri vei til dybde (Pokédex).** Målet (Instructions §2D) er at brukeren kjenner *hundrevis* av selskaper overfladisk, med ett tap til full dybde. «Flust av selskaper» er et mål i seg selv – universet skal være romslig og voksende (§2).
4. **Ingen kuratorisk tilbakekobling til blindspillet.** Å utforske et selskap i Kartoteket påvirker **ikke** hvilke kort du får i blindrundene (din beslutning). Begrunnelse: Kartoteket er nåtid/ekte, blindkortene er historiske/abstraherte – å kjenne dagens Apple røper ikke skjebnen til en 2014-blind-Apple. Anonymiteten hviler på universstørrelse (Instructions §2D), ikke på brukerens uvitenhet. *Loopen beholdes likevel begge veier* (§8): reveal → «Legg til i Kartoteket», og din egen blindhistorikk vises *på* selskapssiden – men ingen av delene endrer kurasjonen.
5. **Retrieval over gjenlesing.** Gjettemodus (§7) gjør passiv lesing om til aktiv gjenhenting – det er gjenhenting, ikke gjenlesing, som bygger varig kunnskap.
6. **Alt AI-innhold batch-generert og cachet** (Instructions §5) – men *uten* leak-sjekk, siden innholdet er navngitt med vilje.

---

## 2. Univers (v1.1): S&P 500 + OBX

* **v1.1-univers: S&P 500 + OBX** (norsk vinkling tidlig). Fordi Kartoteket er nåtids-basert, trengs kun **dagens konstituenter** – ikke den temporale `index_constituents`-rekonstruksjonen (02 §4.2) blindspillet krever. Et enkelt nåværende medlemskap holder.
* **Multivaluta er greit her.** Kartoteket viser *ekte absolutte tall*, så norske selskaper vises i NOK, amerikanske i USD (valutamerket). Det trengs **ingen** felles benchmark/alpha i Kartoteket (det er utforskning, ikke scoring) – så valuta er bare et visningsattributt (`companies.currency`, 02 §4). Verdsettelsesmultipler er uansett valuta-agnostiske forhold.
* **«Flust av selskaper» / utvidbarhet:** den enkle datapaten (§1.2) gjør det billig å legge til flere univers senere (Nasdaq-bredde, STOXX, flere Oslo Børs-lister). v1.1 låser S&P 500 + OBX; arkitekturen forutsetter vekst.
* ⚠️ **FMP-dekning for Oslo Børs må verifiseres** (vi har kun verifisert US-tickere): bekreft `profile`/`income-statement`/`historical-price-eod` for `.OL`-tickere (f.eks. `EQNR.OL`, `DNB.OL`) på Premium, samt at `available-exchanges`/screener kan filtrere Oslo Børs. Egen liten probe (jf. metoden i `fmp_api_questions.md`).
* **Ikke å forveksle med Real-Time Mode (08):** «nåtid» her betyr *dagens snapshot* (fundamentaler oppdatert kvartalsvis, kurs/sparkline daglig EOD), ikke en live-tickende portefølje. Real-Time Mode er en egen, senere modus.

---

## 3. Datamodell (delta mot 02)

Det meste finnes i 02 §7/§9: `company_profiles` (AI-innhold, public-read), `collections` (lagrede, RLS), `decks`/`deck_cards`. Tre presiseringer/tillegg:

```sql
-- (A) NY: dekningssporing (Pokédex) – «sett», ikke bare «lagret».
-- 'collections' fanger LAGREDE selskaper; dekningsmeteren trenger SETTE.
create table kartotek_views (
  user_id     uuid   not null references profiles(id) on delete cascade,
  company_id  bigint not null references companies(id),
  first_seen  timestamptz default now(),
  deep_dived  boolean default false,         -- åpnet full profil (opp-swipe)
  primary key (user_id, company_id)
);
alter table kartotek_views enable row level security;
create policy own_views on kartotek_views
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- (B) Denormaliserte NÅTIDS-felt på company_profiles (fylt av refresh-jobben, 03).
--     Lar front-laget serveres uten å regne hero-tall on-the-fly.
alter table company_profiles
  add column currency      text,
  add column hero_metrics  jsonb,   -- { pe, ps, market_cap, dividend_yield, roic, ... } (ekte, absolutte)
  add column sparkline     jsonb,   -- komprimert ~1–5 års kurs for forsiden
  add column index_codes   text[];  -- nåværende medlemskap: {'SP500'}, {'OBX'}, ...
```

* **(C) Index-medlemskap (nåtid):** `company_profiles.index_codes` (array) er nok for Kartoteket (current). Decks for hele indekser («S&P 500», «OBX») kan enten materialiseres som `decks(type='screen', definition={index:'OBX'})` eller leses direkte fra `index_codes`. Vi trenger *ikke* `index_constituents`-historikken her.
* **`collections.source`** får verdien `'kartotek'`/`'deck'`/`'search'`/`'daily_company'` (02 §9 hadde allerede disse).
* **Gjettemodus-statistikk (valgfri, lett):** per-bruker treffrate kan ligge i en liten `kartotek_guesses(user_id, company_id, metric, correct, created_at)` eller bare aggregeres i analytics – ikke kritisk for v1.1; start uten, legg til hvis featuren viser seg verdt å spore.

*Hvorfor `kartotek_views` er nødvendig:* «Du kjenner 38 % av OBX» (§6) krever *sett*-telling. `collections` teller bare aktivt lagrede (en delmengde). Skillet «sett vs lagret» er to ulike mål (dekning vs samling).

---

## 4. Decks (kuraterte + screen-genererte)

Decks er bunkene man swiper (02 §9 `decks`/`deck_cards`). To typer:

* **Kuraterte** (`type='curated'`): håndplukkede `deck_cards` (posisjonert). Eksempler: «2008-overleverne», «Utbytte-aristokrater», temabunker.
* **Screen-genererte** (`type='screen'`, `definition jsonb`): bygget fra FMP `company-screener` (verifiserte filtre, 05 §8.7: `marketCapMore/LessThan`, `sector`, `industry`, `country`, `exchange`, `isEtf/Fund`, `isActivelyTrading`). Eksempler: «S&P 500 Tech», «OBX», «Nye på børs siste 2 år».
  * **Fundamentale screens** («ROIC > 15 % i 10 år») dekkes *ikke* av screeneren alene – de krever join mot `key-metrics` (`returnOnInvestedCapital`) over tid (05 §8.7-merknad). Slike decks materialiseres av en batch-jobb som evaluerer kriteriet mot `financials`/key-metrics og fyller `deck_cards`.
* **«Dagens selskap»** (egen fra Dagens Runde): ett navngitt Kartotek-kort per dag, lav terskel (Instructions §2D). Seedet på dato for et felles delingspunkt, men *ikke* anonymt og *uten* spill-scoring – ren utforskning. Distinkt fra **Dagens Runde** (den blinde, scorede 5-kort-batchen, 04 §7).

---

## 5. Kortanatomi (lagvis, ekte tall)

Seks lag (Instructions §2D), progressive disclosure. **Kontrast til blindkortet:** her vises navn, ticker og *absolutte beløp* – anonymiseringsreglene i Instructions §3 gjelder *kun* blindkort, ikke Kartoteket.

| Lag | Innhold | Datakilde |
|---|---|---|
| **0 Front** | Navn, ticker, sektor, **énsetnings forretningsmodell** (AI), 3–4 hero-tall (ekte: P/E, market cap i valuta, yield), sparkline | `company_profiles.{one_liner, hero_metrics, sparkline}` |
| **1 Forretning** | Segmenter, inntektsmiks, moat | `revenue-product/geographic-segmentation` (05 §8.7) → `company_profiles.segments`; `moat` (AI) |
| **2 Historikk** | 10 år omsetning/EPS/marginer/FCF | `financials` (ekte, absolutte; fl_chart) |
| **3 Verdsettelse** | Multipler vs egen historikk + vs peers | `financials`/`ratios` (egen) + peer-sett (samme sektor) |
| **4 Siste kvartal** | **AI-sammendrag fra tall-deltas** (ingen transkript) | siste vs forrige kvartal i `financials` → `company_profiles.last_earnings_summary` |
| **5 Bull/Bear** | To setninger hver (tosidig tenkning) | `company_profiles.{bull, bear}` (AI) |

**Lag 4 – earnings uten transkript (din beslutning):** siden `earning-call-transcript` krever Ultimate (05 §10), genereres «Siste kvartal» som et **tall-drevet** AI-sammendrag fra de faktiske kvartals-deltaene: omsetning YoY/QoQ, margin-bevegelser (bps), EPS-endring, FCF-vending, gjeldsendring. Ærlig og konkret («Omsetning +12 % å/å, bruttomargin ned 180 bps, FCF positiv for første gang på fire kvartaler») – men uten ledelses-sitater eller guidance (som krever transkript/estimater). Lag 4 kan **oppgraderes** til ekte transkript-sammendrag senere hvis en kilde (Ultimate/Quartr) tas inn – `earnings_summaries` (02 §7) er allerede klar.

---

## 6. Swipe & samlingsmekanikk

### 6.1 Swipe (gjenbruker 06s rig)
* **Høyre = lagre i «Min samling»** (`collections`, source='kartotek'). **Venstre = neste.** **Opp = deep-dive** (full lagvis profil; setter `kartotek_views.deep_dived=true`). **Langt trykk = gjettemodus** (§7).
* Hver visning skriver `kartotek_views` (sett) – grunnlaget for dekning.

### 6.2 Pokédex-mekanikk
* **Dekningsmetere:** per deck/indeks: `sette / totalt i universet` → «Du kjenner 38 % av OBX». Bruker `kartotek_views` ⋈ deck/`index_codes`.
* **Badges:** per sektor/indeks fullført (config-terskler).
* **«Hva har skjedd siden sist»:** når et nytt kvartal lastes (03 kvartalsvis refresh), løftes lagrede selskaper fram med et delta-flagg – naturlig bro mot Real-Time Mode (08) senere.
* **Min samling:** egen visning av `collections`, med din blindhistorikk per selskap (§8).

---

## 7. Gjettemodus (aktiv læring)

* Skjul ett hero-tall på et kort og be brukeren gjette **intervall** før avsløring («P/E over eller under 20?», «brutto­margin: <30 % / 30–50 % / >50 %?»).
* Ren lærings-interaksjon, *ikke* den kompetitive blind-scoringen (01). Eventuell per-bruker treffrate vises diagnostisk («Din verdsettelses-magefølelse: 64 % treff») – valgfri sporing (§3-C).
* Pedagogikk: retrieval practice (§1.5). Gjør Kartoteket aktivt, ikke bare bla-bart.

---

## 8. Koblingen til blindspillet (loopen – uten kurasjonseffekt)

Tre koblingspunkter fra Instructions §2D, justert for «ingen effekt» (§1.4):

1. **Forward (beholdt):** reveal-skjermen (06 §10) har «Legg til i Kartoteket» → `collections(source='reveal')`.
2. **Revers (beholdt):** på et selskaps Kartotek-side vises **din egen blindhistorikk** for det selskapet: «Du shortet dette i en 2019-runde – det steg 212 % på 5 år.» Dette joiner `game_sessions`⋈`decisions`⋈`batch_cards` på `company_id` (02 §8 `ix_batch_cards_company`). Det viser *din fortid*, og påvirker ingenting framover.
3. **Kurasjonseffekt (fjernet):** Curator nedvekter **ikke** utforskede selskaper (§1.4). Verken Dagens Runde (global, kan uansett ikke per-bruker-filtreres) eller øving justeres. (Dette forenkler 04 §10s «valgfri nedvekting»-note – den utgår.)

*Hvorfor dette er trygt:* blindkortet for Apple er Apple *slik det så ut på en historisk beslutningsdato, anonymisert*; Kartotek-Apple er Apple *i dag, navngitt*. Gjenkjenning på tvers er læring, ikke lekkasje – og overlappen er strukturelt liten fordi de to visningene er ulike i tid og form.

---

## 9. Datapipeline (Kartotek-tillegg til 03)

Gjenbruker entitets-stadiet (03 S2) og kursene (S4), men **hopper over** S1-survivorship, point-in-time-S3-disiplinen, leak-sjekken (S7) og anonymiseringen. Tillegg:

* **Nåtids-snapshot-refresh (kvartalsvis + daglig):** fyll `company_profiles.{hero_metrics, sparkline, currency, index_codes}` fra siste `financials` + siste `prices` + nåværende konstituentliste. Kvartalsvis for fundamentaler, daglig EOD for kurs/sparkline.
* **AI-generering (batch, cachet, INGEN leak-sjekk):** `one_liner`, `moat`, `bull`, `bear`, `last_earnings_summary` (fra tall-deltas, §5). Regenereres ved nye kvartalstall.
* **Segmenter:** `revenue-product/geographic-segmentation` → `company_profiles.segments` (05 §8.7).
* **OBX-ingest:** nåværende OBX-konstituenter + `.OL`-`profile`/`income-statement`/`prices` (NOK). Forutsetter FMP-dekning verifisert (§2).
* **Screen-decks:** batch-jobb som evaluerer deck-`definition` (screener ± key-metrics-join) og fyller `deck_cards`.

*Merk:* Kartoteket bruker gjerne FMPs **nåtids**-endepunkter (`*-ttm`, `key-metrics-ttm`) for hero-tall – de er point-in-time-ubrukelige (05 §8.3) men korrekte for «nå».

---

## 10. API (utvider 05)

Navngitt innhold er public-read (RLS som `company_profiles`); bruker-spesifikt krever JWT.

* `GET /v1/companies/{id}` – full lagvis profil (utvider 05 §4.4 fra «frø» til alle 6 lag).
* `GET /v1/decks` · `GET /v1/decks/{id}` – decks + kort (posisjonert).
* `GET /v1/decks/{id}/coverage` – brukerens dekning (`kartotek_views` ⋈ deck).
* `GET /v1/kartotek/daily` – Dagens selskap.
* `POST /v1/collections` · `DELETE /v1/collections/{company_id}` – samling (05 §4.5; kan også gå Supabase-direkte via RLS).
* `POST /v1/kartotek/views` – marker sett/deep-dived (batchbar; eller Supabase-direkte).
* `GET /v1/companies/{id}/blind-history` – brukerens egne blindvalg for selskapet (§8-2; auth, kun egne rader).

Caching: navngitt selskaps-/deck-innhold er likt for alle og kan caches aggressivt (CDN); bruker-spesifikt (coverage, blind-history, collections) caches ikke.

---

## 11. Frontend (utvider 06)

Gjenbruker `GameCardView`/swipe-rammen og tema (06 §2–§3). Nye skjermer/widgets:

* `KartotekHomeScreen` – decks-galleri + dekningsmetere + «Dagens selskap».
* `KartotekDeckScreen` – swipe gjennom en deck (samme rig som spillet).
* `DeepDiveScreen` – de 6 lagene, progressive disclosure (tabs/accordion), fl_chart for historikk.
* `GuessModeOverlay` – skjul-og-gjett på ett hero-tall.
* `CoverageMeter`, `CollectionScreen`, `BlindHistoryStrip` (på deep-dive).
* **Ekte tall vises** med valutamerke (NOK/USD); kontrast til blindkortets bånd/indekserte serier. Material 3 + samme rolige estetikk (06 §14) – Kartoteket er ren utforskning, så her er det helt greit med rikere datatetthet (tabeller, grafer) enn det minimalistiske blindkortet.

---

## 12. Grensesnitt mot nabo-specs

* **← 02_datamodell:** bygger på `company_profiles` (+ delta §3), `collections`, `decks`/`deck_cards`; ny `kartotek_views`. Alt navngitt innhold er public-read; bruker-rader RLS.
* **← 03_data_pipeline:** nåtids-refresh + AI-generering uten leak-sjekk/anonymisering/point-in-time (§9).
* **← 05_api:** utvider `GET /v1/companies/{id}` og samlings-endepunktene; nye deck/coverage/daily/blind-history-ruter.
* **← 06_frontend:** gjenbruker swipe-rig, tema, modeller.
* **← 01/04:** **ingen** kurasjons- eller scoring-kobling (§1.4, §8-3) – Kartoteket rører ikke blindspillets integritet. Reverse-lenken (§8-2) leser kun `game_sessions`/`batch_cards`.

## 13. Åpne beslutninger

1. **OBX-dekning i FMP** (§2): verifiser `.OL`-tickere før OBX-decks bygges. Hvis tynt – start S&P 500-only og legg OBX til når dekning er bekreftet.
2. **Hero-tall on-serve vs denormalisert** (§3-B): jeg foreslår denormalisert (`company_profiles.hero_metrics`, fylt av refresh-jobben). Bekreft, eller regn on-serve i v1.1 hvis enklere.
3. **Peer-sett for lag 3** (verdsettelse vs peers): hvordan defineres peers? Forslag: samme `sector`/`industry` + cap-bånd, topp-N på likhet. Lås metode.
4. **Gjettemodus-sporing** (§3, §7): spore treffrate per bruker (egen tabell) eller la det være en flyktig interaksjon i v1.1? Forslag: flyktig først.
5. **«Dagens selskap»-seed & deling:** skal den ha et delingskort (som Dagens Runde), eller forbli en stille daglig vane? Forslag: stille i v1.1.
6. **Universutvidelse etter v1.1** (§2): rekkefølge for «flust av selskaper» (Nasdaq-bredde, STOXX, flere OSE-lister)? Drives av FMP-dekning + brukerinteresse.