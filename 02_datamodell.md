# 02_datamodell.md – KAP Spesifikasjon: Datamodell & Persistens

> **Dokumentserie:** `01_scoring` ✓ · **`02_datamodell` (dette)** · `03_data_pipeline` · `04_curator` · `05_api` · `06_frontend_gameloop` · `07_kartoteket` · `08_realtime`
> Denne spec'en definerer det fysiske skjemaet (PostgreSQL/Supabase), tidssemantikken som gjør spillet til en *ærlig* backtest, sikkerhetsgrensen som hindrer at fasiten lekker, og grensesnittene de andre specene skriver/leser mot. DDL her er ment som utgangspunkt for første migrasjon.

---

## 1. Designprinsipper

1. **Point-in-time er ikke en feature, det er korrekthetskravet.** Hver rad som mater et kort må kunne svare på spørsmålet «var dette kjent på beslutningsdatoen?». Brytes dette, lærer appen bort etterpåklokskap – stikk i strid med hele tesen (Instructions §4). Modellen er derfor *bitemporal* der det trengs: vi skiller *gyldighetstid* (hvilken periode tallet gjelder) fra *transaksjonstid* (når tallet ble offentlig kjent).
2. **Sannhet og fasade er fysisk adskilt.** Det anonymiserte kortet (det brukeren ser) og fasiten (ticker, navn, alpha, clue) lever slik at fasiten *aldri kan nås via en klient-lesbar sti*. Anonymisering håndheves på tabell-/tilgangsnivå, ikke i UI-laget. Et spill der svaret ligger i en offentlig tabell og bare skjules i appen, er allerede lekket.
3. **Spillhendelser er en uforanderlig logg, ikke en projeksjon.** Basistabellene endrer seg (ny data ingestes, narrativer regenereres). Men hva *en gitt bruker så en gitt dag* må fryses. Vi event-sourcer kortet: den serverte JSON-en snapshotes på batch-kortet. Det er bevisst denormalisering, og den er riktig nettopp fordi kilden er foranderlig.
4. **Analytics-grunnlaget legges dag 1.** «Din investorprofil» (Instructions §8, scoring §4.3 om empirisk IC) krever at hvert valg kan kobles til kortets *features på beslutningstidspunktet*. Siden kort-payloaden er frosset, er den koblingen triviell og billig – uten å rekonstruere point-in-time i ettertid.
5. **Surrogatnøkler internt, naturlige nøkler kun for visning.** Ticker er ikke en stabil identitet (symboler gjenbrukes etter delisting). Alt refererer `company_id` (surrogat); ticker er et attributt som kan endre seg.
6. **Ikke optimaliser før målingene krever det.** Partisjonering, TimescaleDB, materialiserte views – alt er løftestenger vi *navngir* men ikke trekker i før volum/profilering tilsier det. MVP-volumet (~1k selskaper × 15 år) er trivielt for Postgres.

---

## 2. Domeneoversikt

Fem domener, med eierskap (hvilken spec som *skriver*):

```
A. Referanse & entitet      companies, index_constituents                 ← 03_pipeline
B. Tidsserier               prices, index_prices, risk_free               ← 03_pipeline
C. Point-in-time finans     financials                                    ← 03_pipeline
D. Kontekst & AI-innhold     macro_context, narratives, company_profiles,  ← 03_pipeline
                            earnings_summaries
E. Spillstruktur            game_batches, batch_cards                     ← 04_curator (seal)
F. Bruker & analytics       profiles, game_sessions, decisions,           ← 05_api / klient
                            collections, decks, deck_cards
```

Avhengighetsretning: F → E → {A,B,C,D}. Scoringmotoren (01) leser B, C og E; skriver F (sesjonsscore). Klienten ser *bare* F (egne rader) + offentlig Kartotek-innhold; alt annet går gjennom FastAPI med service-rolle (§10).

---

## 3. Tidssemantikk – kjernen i korrektheten

### 3.1 Tre datoer som ikke må forveksles

| Dato | Betydning | Konsekvens hvis feil |
|---|---|---|
| `period_date` | Regnskapsperiodens slutt (gyldighetstid) | – |
| `filing_date` | Når tallet ble *offentlig* (transaksjonstid) | Look-ahead: kortet viser tall ingen hadde |
| `decision_date` (= `t0`) | Batchens beslutningsanker | Definerer hva som var «kjent» og når avkastningen starter |

**Regelen (harmoniserer 01_scoring §2):** Curator velger `decision_date` for batchen (ett makrobilde for hele bunken). For hvert selskap hentes *siste rapporterte tall med `filing_date <= decision_date`*. Avkastningen måles fra første handelsdag `>= decision_date`. Siden alle filings på kortene per konstruksjon er `<= decision_date <= t0_return`, er look-ahead utelukket. Scoringspec'ens formulering «t0 = første handelsdag etter siste filing_date» er det samme kravet sett fra motsatt kant; **denne spec'en er normativ: `t0 = decision_date`, og point-in-time-spørringen (§6.2) er look-ahead-vakten.**

### 3.2 Survivorship: universet er temporalt

Den dyreste fellen. Bygger du universet fra *dagens* indeksliste finnes bare overleverne, og Long blir systematisk «for riktig». Universet for dato `D` må være indeksens *historiske* medlemmer per `D`, inkludert selskaper som senere ble delistet. Dette modelleres som et temporalt medlemskap (`index_constituents`, §4.2) – ikke en flat liste.

### 3.3 Restatements (bitemporalitet i praksis)

Et selskap rapporterer Q1, og *restater* det et år senere. For point-in-time vil vi ha versjonen *som var kjent på `decision_date`* – ikke den korrigerte. Derfor er nøkkelen `(company_id, period_date, period_type, filing_date)`: hver restatement er sin egen rad med sin egen `filing_date`. Spørringen i §6.2 plukker «siste versjon kjent per `decision_date`». *Forbehold (verifisert Q21):* FMP gir i praksis **kun én versjon per periode** (ingen restatement-historikk; testet på AAPL 40 år + GE). Ekte restatement-historikk er en åpen post (§14). Skjemaet er klart for det selv om datakilden i v1 ikke leverer det – bitemporaliteten er fremtidssikring.

*Generaliserbart:* dette er lærebok-bitemporalitet (valid time × transaction time). Samme mønster gjelder enhver «hva visste vi da»-spørring – revisjon, compliance, audit trails.

---

## 4. Domene A – Referanse & entitet

```sql
create table companies (
  id              bigint generated always as identity primary key,
  ticker          text not null,                 -- visning/oppslag; IKKE stabil identitet
  name            text not null,
  sector          text,
  industry        text,
  sector_coarse   text,                           -- anonymiseringstrygg grovsektor (kortet)
  country         text default 'US',
  currency        text default 'USD',
  is_delisted     boolean default false,
  delisted_date   date,
  delisting_reason text,                          -- 'bankruptcy'|'acquired'|'merged'|'other'
  iconic          boolean default false,          -- for gjenkjennelig -> ekskluder fra blind/daily
  created_at      timestamptz default now()
);

-- Ticker-gjenbruk: kun AKTIVE selskaper må ha unik ticker.
-- En delistet rad kan dele symbol med et nytt aktivt selskap.
create unique index uq_companies_active_ticker
  on companies (ticker) where is_delisted = false;
```

**Hvorfor surrogat + partiell unik:** Når et konkursrammet selskaps ticker frigjøres og gjenbrukes (reelt fenomen – **verifisert med BBBY**, hvis dividend-adjusted-serie inneholder både Bed Bath & Beyond fram til konkurs 2023 og et nytt selskap etterpå, Q12), ville en global `unique(ticker)` enten blokkere ingest eller tvinge oss til å overskrive historikk. `company_id` gir stabil identitet; den partielle unike indeksen holder *aktive* tickere entydige for oppslag, mens delistede beholder sin ticker for visning uten å kollidere. Historisk ticker-mapping bygges fra `historical-sp500-constituent.removedTicker` (03 S1), siden `symbol-change` kun dekker nylige bytter. `iconic`-flagget mater Curators ekskludering av de mest gjenkjennelige (Instructions §3, anonymiseringsregler).

```sql
create extension if not exists btree_gist;

create table index_constituents (
  id          bigint generated always as identity primary key,
  index_code  text not null,                      -- 'SP500', 'OBX', ...
  company_id  bigint not null references companies(id),
  membership  daterange not null,                 -- [inn, ut) ; ut = 'infinity' hvis nåværende
  exclude using gist (index_code with =, company_id with =, membership with &&)
);
```

**Hvorfor `daterange` + exclusion-constraint:** Et selskap kan gå inn og ut av en indeks flere ganger. `daterange` gir oss `membership @> D` for «var med på dato D», og exclusion-constraint (krever `btree_gist` for likhets-operatorene) *garanterer på databasenivå* at samme selskap aldri har overlappende medlemskap i samme indeks – datakvalitet håndhevet av skjemaet, ikke av applikasjonskode.

---

## 5. Domene B – Tidsserier

```sql
create table prices (
  company_id bigint not null references companies(id),
  date       date   not null,
  adj_close  numeric not null,        -- TOTALAVKASTNINGS-justert (splitt + utbytte reinvestert)
  close_raw  numeric,                  -- ujustert, kun for debugging/visning
  primary key (company_id, date)
);
create index ix_prices_date on prices (date);   -- tverrsnitt (alle selskaper en dato)

create table index_prices (
  index_code text not null,           -- 'SP500TR'
  date       date not null,
  tr_close   numeric not null,        -- total return-nivå
  primary key (index_code, date)
);

create table risk_free (
  date        date not null,
  tenor       text not null default '3M',
  annual_rate numeric not null,       -- f.eks. 0.0175 = 1.75 % (annualisert quote)
  primary key (date, tenor)
);
```

**`adj_close` er total-return-justert, ikke bare splittjustert.** Dette er ikke valgfritt: bruker du kursavkastning, ser utbytteselskaper – *selve Buffett-segmentet* – systematisk dårligere ut, og appen motbeviser sin egen tese (Instructions §4.3, scoring §2). `close_raw` beholdes kun for feilsøking.

**`risk_free`-konvensjon (må matche scoring §2/§6.6):** T-bill er quotet annualisert. Daglig faktor på handelsdager: `(1 + annual_rate)^(1/252) − 1`. Den batch-frosne `R_f`/`r_f` (§8) regnes geometrisk over `[t0, t1]` og lagres på batchen for determinisme – `alpha_cash` skal være revisjonsbar.

**Volum/partisjonering:** ~1k selskaper × 15 år × 252 ≈ 3,8M rader. Trivielt med PK-indeksen. *Ikke* partisjoner nå. Løftestang for senere (globalt univers eller intradag): range-partisjon `prices` på år, ev. `BRIN`-indeks på `date`. Premature partisjonering koster vedlikehold uten gevinst på dette volumet.

---

## 6. Domene C – Point-in-time finans

```sql
create table financials (
  id            bigint generated always as identity primary key,
  company_id    bigint not null references companies(id),
  period_date   date not null,                    -- periodeslutt (gyldighetstid)
  period_type   text not null check (period_type in ('annual','quarter','ttm')),
  filing_date   date not null,                    -- offentliggjort (transaksjonstid)
  revenue numeric, net_income numeric, eps numeric, fcf numeric,
  pe numeric, ps numeric, ev_ebit numeric,
  debt_to_equity numeric,
  gross_margin numeric, operating_margin numeric, net_margin numeric,
  roic numeric,
  cap_category text check (cap_category in ('small','mid','large')),
  extra jsonb default '{}'::jsonb,                 -- overflow for sjeldne metrikker
  unique (company_id, period_date, period_type, filing_date)
);
create index ix_fin_company_filing on financials (company_id, filing_date desc);
create index ix_fin_company_period on financials (company_id, period_date desc);
```

**Bredt skjema + `extra` JSONB:** Metrikkene er stabile og kjente → faste kolonner (raskt, typesikkert, indekserbart). EAV ville gitt fleksibilitet vi ikke trenger og spørringer vi ikke vil ha. JSONB-`extra` er trykkventil for det sjeldne.

### 6.2 Kanonisk spørring (look-ahead-vakten — bli denne fixture)

«Siste kjente tall per `period_type`, som av `decision_date`, med restatements håndtert»:

```sql
with as_of as (                       -- 1) dedupliser restatements til versjonen kjent ved decision_date
  select distinct on (period_type, period_date)
         *
  from financials
  where company_id = $company_id
    and filing_date <= $decision_date
  order by period_type, period_date desc, filing_date desc
)
select distinct on (period_type)      -- 2) siste periode per type
       *
from as_of
order by period_type, period_date desc;
```

Steg 1 plukker, for hver periode, den seneste `filing_date <= decision_date` (riktig restatement-versjon). Steg 2 plukker seneste periode per type. Resultatet er nøyaktig det kortet skal vise. *3-års CAGR* og lignende avledes herfra ved seal (ikke lagret rått) og fryses i kortets payload (§8).

---

## 7. Domene D – Kontekst & AI-innhold

```sql
create table macro_context (
  id             bigint generated always as identity primary key,
  date           date not null,
  region         text not null default 'US',
  rate_level     text check (rate_level in ('low','neutral','high')),
  rate_direction text check (rate_direction in ('rising','flat','falling')),
  inflation      numeric,
  gdp_growth     numeric,
  ai_sentence    text,                             -- batch-generert kontekstsetning
  unique (date, region)
);

create table narratives (
  id                 bigint generated always as identity primary key,
  company_id         bigint not null references companies(id),
  decision_date      date not null,
  horizon_years      int  not null,
  narrative          text not null,                -- 2 setninger, ANONYMISERT (vises på kort)
  sector_sentiment   text,                         -- vises på kort
  clue               text,                         -- KUN reveal
  result_explanation text,                         -- KUN reveal
  leak_check_passed  boolean default false,        -- jf. Instructions §5 steg 15
  llm_model          text,
  generated_at       timestamptz default now(),
  unique (company_id, decision_date, horizon_years)
);
```

**Skille kortvendt vs reveal allerede i kilden:** `narrative`/`sector_sentiment` er anonymisert og kortvendt; `clue`/`result_explanation` er reveal-innhold. Begge snapshotes inn i batch-kortet ved seal (§8) – den anonymiserte delen i payloaden, reveal-delen i sannhets-laget. `leak_check_passed` er en *hard* seal-precondition: et narrativ som ikke har bestått leak-sjekken kan ikke inngå i en sealet batch.

```sql
-- Kartoteket (v1.1, IKKE-anonymisert, nåværende snapshot). Public-read (§10).
create table company_profiles (
  company_id           bigint primary key references companies(id),
  one_liner            text,
  segments             jsonb,
  moat                 text,
  bull                 text,
  bear                 text,
  last_earnings_summary text,
  last_earnings_period  date,
  refreshed_at         timestamptz default now()
);

create table earnings_summaries (                  -- Quartr-light (v1.1)
  id           bigint generated always as identity primary key,
  company_id   bigint not null references companies(id),
  period_date  date not null,
  filing_date  date,
  summary      text,
  unique (company_id, period_date)
);
```

`narratives` (anonymisert, decision-date-spesifikk, for blindmodus) og `company_profiles`/`earnings_summaries` (navngitt, nåværende, for Kartoteket) er bevisst *to ting* – ulik anonymiseringsstatus, ulik tilgangsklasse.

---

## 8. Domene E – Spillstruktur (eies av Curator)

```sql
create table game_batches (
  id              bigint generated always as identity primary key,
  mode            text not null check (mode in ('junior','manager','realtime')),
  region          text not null default 'US',
  benchmark_index text not null default 'SP500TR',
  decision_date   date not null,                   -- t0 (look-ahead-anker)
  horizon_years   int  not null,                   -- H
  seed            bigint not null,                 -- deterministisk kurasjon
  is_daily        boolean default false,
  daily_date      date,                            -- unik når is_daily
  difficulty      numeric,                         -- alpha-spredning (matchmaking, §01-backlog)
  curator_version text,
  curator_params  jsonb,                           -- constraints brukt (reproduserbarhet)
  -- Frosne benchmark/risikofri-størrelser (determinisme, jf. 01_scoring §2/§6.6):
  R_m numeric, r_m numeric, R_f numeric, r_f numeric, alpha_cash numeric,
  status          text not null default 'draft'
                  check (status in ('draft','sealed','live','archived')),
  created_at      timestamptz default now(),
  sealed_at       timestamptz
);
create unique index uq_batches_daily on game_batches (daily_date) where is_daily;

create table batch_cards (
  batch_id   bigint not null references game_batches(id) on delete cascade,
  card_no    int    not null,
  company_id bigint not null references companies(id),

  -- PUBLIC-lag: nøyaktig det API-et serverer (anonymisert, uforanderlig snapshot)
  public_payload jsonb not null,
  -- public_payload = { macro:{...}, fundamentals:{pe,ps,debt_to_equity,margins,roic},
  --                    growth:{rev_cagr_3y,eps_cagr_3y}, cap, sector_coarse,
  --                    narrative, sector_sentiment }    -- ALDRI navn/ticker/beløp

  -- Analytics-flate kopier (settes ved seal; indekser for profil-spørringer):
  f_pe numeric, f_debt_to_equity numeric, f_rev_cagr numeric,
  f_sector text, f_cap text,

  -- TRUTH-lag: beregnet ved seal, KUN reveal:
  name text,
  alpha numeric,                       -- annualisert alpha (scoring §2)
  ret_cum numeric, ret_ann numeric,
  event text default 'none' check (event in ('none','delisted','acquired')),
  clue text, result_explanation text,

  primary key (batch_id, card_no)
);
create index ix_batch_cards_company on batch_cards (company_id);  -- Kartotek-kryssreferanse
```

**Hvorfor `public_payload` som frosset JSONB:** Det er den uforanderlige kvitteringen på hva brukeren faktisk så (prinsipp 3). Den kan ikke regnes på nytt fra basistabellene senere, for de har endret seg. Den gjør også API-et trivielt (server payloaden, ferdig) og analytics presise.

**Hvorfor `f_*`-kolonner i tillegg til JSONB:** «Din investorprofil» kjører aggregerte spørringer over millioner av `decisions` koblet til kort-features. Å parse JSONB i hver slik spørring er dyrt; flate, indekserbare kopier av de få feature-ene vi profilerer på (P/E, gjeld, vekst, sektor, cap) er en bevisst denormalisering for analytics. (Alternativt: `generated columns` fra JSONB.)

**Hvorfor sannhet og fasade i samme tabell, men tabellen er service-only:** Vi trenger `company_id` for å regne fasit, og fasit-kolonnene for reveal. Hele `batch_cards` er *aldri klient-lesbar* (§10); FastAPI serverer kun `public_payload` (+ `card_no`) og returnerer sannhet *i submit-svaret*. Ekstra herding (mindre blast-radius): splitt `name/alpha/clue/...` ut i `batch_card_truth` med egen (fraværende) policy. Anbefalt som v1.1-herding; i v1 holder service-only-grensen.

### 8.1 Precompute av fasit (ytelse + determinisme)

Kort-alpha er *brukeruavhengig* – det er bare aksjens prestasjon. Derfor: når Curator sealer en historisk batch (der `t1` ligger i fortiden), beregnes per kort `ret_cum, ret_ann, alpha, event` én gang og fryses på `batch_cards`. Submit-tid for **Junior** blir da ren aritmetikk (anvend valg på frossen kort-alpha) – kritisk når millioner spiller samme Dagens Runde.

**Manager** trenger porteføljens NAV-serie (avhenger av vekter → kan ikke precomputes per bruker). Den regnes ved submit, men kun fra `prices` for batchens 8–12 tickere over `[t0−2år, t1]` – noen tusen rader, billig. Vi lagrer *ikke* per-kort daglige `G_i(t)`; vi spør dem (åpen post §14 hvis profilering viser at det trengs).

---

## 9. Domene F – Bruker & analytics

```sql
-- Kjerneschema: INGEN hard FK til Supabase (kjører også på lokal Docker-Postgres).
-- `id` = auth.uid() (JWT sub), satt av FastAPI/Supabase. Supabase-koblingen
-- (FK mot auth.users + signup-trigger + RLS) ligger i EGEN Supabase-only migrasjon (§10).
create table profiles (
  id              uuid primary key,            -- = auth.uid(); FK mot auth.users kun i Supabase-migrasjonen
  display_name    text,
  knowledge_level text default 'beginner'
                  check (knowledge_level in ('beginner','intermediate','expert')),
  is_anonymous    boolean default true,
  created_at      timestamptz default now()
);

create table game_sessions (
  id            bigint generated always as identity primary key,
  user_id       uuid not null references profiles(id) on delete cascade,
  batch_id      bigint not null references game_batches(id),
  mode          text not null,
  is_daily      boolean not null default false,    -- denormalisert for daily-unikhet
  started_at    timestamptz default now(),
  submitted_at  timestamptz,
  score         numeric, bonus numeric, hit_rate numeric,
  manager_extra jsonb                              -- TE, IR, sharpe, n_eff, korr, ex_ante (01 §7)
);
-- Dagens Runde: ett forsøk per bruker per daglig batch. Øvingsbatcher: fri replay.
create unique index uq_session_daily
  on game_sessions (user_id, batch_id) where is_daily;

create table decisions (
  id          bigint generated always as identity primary key,
  session_id  bigint not null references game_sessions(id) on delete cascade,
  card_no     int not null,
  choice      text not null check (choice in ('long','short','cash','skip')),
  weight      numeric,                              -- KUN Manager; null/ignorert i Junior
  response_ms int,                                  -- reaksjonstid (analytics)
  created_at  timestamptz default now(),
  unique (session_id, card_no)
);

create table collections (                          -- Kartoteket «Min samling»
  user_id    uuid   not null references profiles(id) on delete cascade,
  company_id bigint not null references companies(id),
  saved_at   timestamptz default now(),
  source     text check (source in ('reveal','deck','search','daily_company')),
  primary key (user_id, company_id)
);

create table decks (                                -- v1.1
  id          bigint generated always as identity primary key,
  title       text not null, description text,
  type        text not null check (type in ('curated','screen')),
  definition  jsonb,                                -- screen-kriterier når type='screen'
  is_active   boolean default true,
  created_at  timestamptz default now()
);
create table deck_cards (
  deck_id    bigint not null references decks(id) on delete cascade,
  company_id bigint not null references companies(id),
  position   int,
  primary key (deck_id, company_id)
);
```

**Sesjon som enhet:** `game_sessions` er én gjennomspilling; `decisions` er valgene i den. Scoren persisteres på sesjonen (denormalisert fra scoringmotorens output, 01 §7) fordi vi vil rangere og vise den uten å regne på nytt. `manager_extra` lagres som JSONB siden det er et reint feedback-objekt vi ikke spør strukturert på.

**Vekting og cash:** `weight` per kort gjelder Manager-longs/shorts; residualen opp til 1.0 er cash (Instructions §2B «resten i cash»). Junior har ingen portefølje → `weight` er null.

**Investorprofil-spørring (hvorfor modellen muliggjør den):**

```sql
-- Systematisk skjevhet: longer brukeren ukritisk lav P/E? (value-trap-tendens)
select width_bucket(bc.f_pe, 0, 60, 12) as pe_bucket,
       avg((d.choice = 'long')::int)      as long_rate,
       avg(bc.alpha)                       as realized_alpha
from decisions d
join game_sessions s on s.id = d.session_id
join batch_cards   bc on bc.batch_id = s.batch_id and bc.card_no = d.card_no
where s.user_id = $user_id
group by pe_bucket order by pe_bucket;
```

Mulig fordi `f_pe` (kortets P/E *på beslutningstidspunktet*) er frosset og indeksert, og `bc.alpha` er fasiten. Samme tabell tjener produktfeature og forskningsdata om tankefeil (Instructions §2 om analytics) – to formål, ett skjema.

---

## 10. Sikkerhetsmodell (RLS) – anonymiseringsgrensen

Dette er den viktigste seksjonen for spillets integritet. **To tilgangsklasser:**

**Klient-lesbar (Supabase-klient, RLS «eier egen rad»):** `profiles`, `game_sessions`, `decisions`, `collections` (egne rader) + `company_profiles`, `decks`, `deck_cards` (public-read – Kartoteket er navngitt *ved design*).

**Service-only (kun FastAPI med service-rolle, ingen klient-policy):** `companies`, `financials`, `prices`, `index_prices`, `risk_free`, `macro_context`, `narratives`, `game_batches`, `batch_cards`. Disse inneholder point-in-time-data og *fasiten*. Postgres RLS er rad-nivå, ikke kolonne-nivå – man kan derfor ikke «skjule ticker-kolonnen» med en policy. Konklusjon: hele `batch_cards` må være utenfor klientens rekkevidde, og FastAPI er eneste vei til kortdata.

```sql
alter table profiles      enable row level security;
alter table game_sessions enable row level security;
alter table decisions     enable row level security;
alter table collections   enable row level security;

create policy own_profile on profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

create policy own_sessions on game_sessions
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy own_decisions on decisions
  for all using (
    auth.uid() = (select user_id from game_sessions s where s.id = session_id)
  );

create policy own_collections on collections
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Kartoteket: public-read
alter table company_profiles enable row level security;
create policy read_profiles on company_profiles for select using (true);
-- (decks/deck_cards tilsvarende)

-- Service-only tabeller: RLS PÅ, INGEN policy => kun service-rollen slipper inn.
alter table batch_cards enable row level security;   -- ingen policy bevisst
-- ... tilsvarende for companies/financials/prices/index_prices/risk_free/
--     macro_context/narratives/game_batches
```

**Supabase-kobling isolert (portabilitet):** `profiles.id` har *ingen* hard FK i kjerneschemaet (§9). En **egen Supabase-only migrasjon** legger til (a) `alter table profiles add constraint profiles_auth_fk foreign key (id) references auth.users(id) on delete cascade`, (b) en signup-trigger som inserter en `profiles`-rad ved ny `auth.users`, og (c) RLS-policyene i denne seksjonen (som bruker `auth.uid()`). På lokal Docker-Postgres hoppes denne migrasjonen over: FastAPI med service-rolle eier all skriving, `profiles` seedes direkte, og `auth.uid()`-policyene er irrelevante (ingen klient-direkte tilgang offline). Hele Supabase-avhengigheten bor dermed i én migrasjonsfil; resten av schemaet er portabelt og kjører på vanlig Postgres.

**Forsvar i dybden:** Selv om all spill-lesning rutes via FastAPI (anbefalt, §14), står RLS som andre lag. En enkelt feilkonfigurasjon skal ikke kunne dumpe svarene. *Prinsipp:* håndhev hemmeligheter på laveste lag som kan håndheve dem – aldri kun i presentasjonslaget.

**Dagens Runde-nyanse:** Alle får samme batch; en bruker som har spilt og fått reveal kan dele svarene (iboende, som Wordle). Akseptabelt for et daglig sosialt spill. For øvings-/ranked-batcher avsløres sannhet kun etter submit, av FastAPI.

---

## 11. Indeksering & ytelse (oppsummert)

| Spørremønster | Indeks |
|---|---|
| Point-in-time finans (§6.2) | `ix_fin_company_filing (company_id, filing_date desc)` |
| Avkastningsserie for batch | `prices` PK `(company_id, date)` |
| Tverrsnitt (alle selskaper én dag) | `ix_prices_date (date)` |
| Univers per dato (§4.2) | GiST på `index_constituents` |
| Aktivt ticker-oppslag | `uq_companies_active_ticker` |
| Daglig batch | `uq_batches_daily` |
| Ett daily-forsøk/bruker | `uq_session_daily` |
| Kartotek-kryssreferanse | `ix_batch_cards_company (company_id)` |
| Investorprofil | `f_*`-kolonner på `batch_cards` |

Løftestenger (ikke nå): range-partisjon `prices`/`financials` på år; `BRIN` på `prices.date`; materialisert view for Dagens Runde-leaderboard (persentil av `game_sessions.score` for dagens batch). Trekk i dem først når profilering tilsier det.

---

## 12. Grensesnitt mot nabo-specs

**→ 01_scoring (oppfyller §7-kontrakten):**
- *Komplette serier* for `[t0−2år, t1]`: `prices` (per ticker), `index_prices` (benchmark), `risk_free` – Curator sealer kun batcher der disse er hullfrie (§13). De to ekstra årene er ex-ante-kovariansens trailing-vindu (Ledoit–Wolf), og er per definisjon før `t0` → look-ahead-trygt.
- *Per-kort alpha* leveres frosset i `batch_cards.{alpha,ret_cum,ret_ann,event}`.
- *Submit-svaret* (01 §7) bygges av: `game_batches.{R_m,r_m,r_f,alpha_cash}` + `batch_cards` truth-lag; `manager_extra` persisteres på `game_sessions`.

**→ 03_data_pipeline (skriver A–D):** populerer `companies` (inkl. delistede, `iconic`), `financials` (med `filing_date`, restatement-rader), `prices` (TR-justert), `index_prices`, `risk_free`, `macro_context`, `narratives` (med `leak_check_passed`). Eier datakvalitets-porten.

**→ 04_curator (skriver E):** velger `decision_date`/`seed`, håndhever constraints (01 §-Curator), beregner og fryser benchmark/rf + per-kort-fasit (§8.1), setter `status='sealed'`. **Seal-preconditions:** (a) hullfrie serier `[t0−2år,t1]` for alle kort; (b) alle narrativer `leak_check_passed`; (c) constraints oppfylt (≥1 vinner/≥1 taper, maks 2/sektor, blandet cap, ekskluder `iconic` i blind/daily); (d) `t1` minst 30 handelsdager i fortiden.

**→ 05_api:** serverer `public_payload` (+ `card_no`), aldri truth før submit; håndhever RLS-grensen (§10).

---

## 13. Datakvalitet & seal-gate (skisse, detaljeres i 03/04)

En batch kan ikke `seal`-es uten at dekningssjekken passerer. Lettvekts implementasjon (unngå tung permanenttabell): en funksjon/CTE som per kort verifiserer maks tillatt gap i `prices` over `[t0−2år, t1]` (f.eks. ≤ 10 handelsdager sammenhengende), at `index_prices`/`risk_free` dekker hele spennet, og at `narratives.leak_check_passed`. Tvilsomme rader fra ingest legges i en `data_quarantine`-tabell (eies av 03) heller enn å slettes – sporbarhet.

---

## 14. Åpne beslutninger (lås før migrasjon kjøres)

1. **Surrogat- vs naturlig nøkkel:** Spec'en anbefaler `company_id` (surrogat) overalt pga. ticker-gjenbruk. Bekreft – det forplanter seg til alle FK-er.
2. **Bitemporal dybde / restatements:** Skjemaet støtter restatement-historikk, men FMP gir **verifisert kun én versjon per periode** (Q21). Anbefaling: lev med as-reported i v1; bitemporaliteten beholdes som fremtidssikring og aktiveres hvis en kilde med restatement-historikk tas inn.
3. **Rut all spill-lesning via FastAPI?** Sterk anbefaling: ja (RLS som andre lag). Bekreft at klienten *aldri* leser `batch_cards`/`game_batches` direkte.
4. **Truth-splitt nå eller v1.1?** Egen `batch_card_truth`-tabell gir mindre blast-radius. Anbefalt v1.1-herding; v1 på service-only.
5. **Partisjonering av `prices`:** Ikke i MVP. Definer terskel (radantall / query-latency) som trigger range-partisjon.
6. **TTM:** Lagre `period_type='ttm'`-rader fra pipeline, eller derive TTM ved seal? (Påvirker `financials`-volum og kort-payload-logikk.)
7. **Per-kort daglig `G_i(t)` for Manager:** Spør ved submit (v1) vs. precompute/lagre. Avgjør hvis Manager-submit-latency blir et problem.
8. **Migrasjonsverktøy:** Alembic (Python-nært, versjonert i repo) vs. Supabase migrations (nært hosting). Velg ett før første migrasjon.

---

## 15. Seeding & testdata

Seed et minimalt fixture-univers (5–10 selskaper, inkl. minst ett delistet og ett oppkjøpt) som matcher **golden fixtures fra 01_scoring §3.3/§4.6**: de samme tallene legges som `batch_cards`-fasit, slik at scoringens enhetstester kjører mot ekte rader og de to specene valideres mot hverandre. Dette binder scoring og datamodell sammen i CI fra dag 1.