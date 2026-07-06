-- KAP core schema — 02_datamodell.md §4–§9, §11 (CP 2.1).
--
-- PORTABLE Postgres only: no reference to Supabase's auth schema anywhere in
-- this file. The Supabase coupling (auth FK, signup trigger, all RLS) lives in
-- the companion migration 20260706120100_supabase_auth_rls.sql, per 02 §10 —
-- skip that one on a plain local Postgres.
--
-- Locked decisions (02 §14): surrogate company_id everywhere (#1); financials
-- keyed bitemporally even though FMP serves one version per period (#2);
-- Supabase migrations as the tool (#8).

create extension if not exists btree_gist;

-- === Domene A – Referanse & entitet (02 §4) ==================================

create table companies (
  id               bigint generated always as identity primary key,
  ticker           text not null,        -- visning/oppslag; IKKE stabil identitet
  name             text not null,
  sector           text,
  industry         text,
  sector_coarse    text,                 -- anonymiseringstrygg grovsektor (kortet)
  country          text default 'US',
  currency         text default 'USD',
  is_delisted      boolean default false,
  delisted_date    date,
  delisting_reason text,                 -- 'bankruptcy'|'acquired'|'merged'|'other'
  iconic           boolean default false, -- for gjenkjennelig -> ekskluder fra blind/daily
  created_at       timestamptz default now()
);

-- Ticker-gjenbruk (verifisert BBBY): kun AKTIVE selskaper må ha unik ticker.
create unique index uq_companies_active_ticker
  on companies (ticker) where is_delisted = false;

create table index_constituents (
  id          bigint generated always as identity primary key,
  index_code  text not null,             -- 'SP500', 'OBX', ...
  company_id  bigint not null references companies(id),
  membership  daterange not null,        -- [inn, ut) ; ut = 'infinity' hvis nåværende
  -- Samme selskap kan aldri ha overlappende medlemskap i samme indeks —
  -- håndhevet av databasen, ikke applikasjonskode.
  exclude using gist (index_code with =, company_id with =, membership with &&)
);

-- === Domene B – Tidsserier (02 §5) ===========================================

create table prices (
  company_id bigint not null references companies(id),
  date       date   not null,
  adj_close  numeric not null,           -- TOTALAVKASTNINGS-justert (splitt + utbytte)
  close_raw  numeric,                    -- ujustert, kun debugging/visning
  primary key (company_id, date)
);
create index ix_prices_date on prices (date);  -- tverrsnitt (alle selskaper en dato)

create table index_prices (
  index_code text not null,              -- 'SP500TR'
  date       date not null,
  tr_close   numeric not null,           -- total return-nivå
  primary key (index_code, date)
);

create table risk_free (
  date        date not null,
  tenor       text not null default '3M',
  annual_rate numeric not null,          -- 0.0175 = 1.75 % (annualisert quote)
  primary key (date, tenor)
);

-- === Domene C – Point-in-time finans (02 §6) =================================

create table financials (
  id            bigint generated always as identity primary key,
  company_id    bigint not null references companies(id),
  period_date   date not null,           -- periodeslutt (gyldighetstid)
  period_type   text not null check (period_type in ('annual','quarter','ttm')),
  filing_date   date not null,           -- offentliggjort (transaksjonstid)
  revenue numeric, net_income numeric, eps numeric, fcf numeric,
  pe numeric, ps numeric, ev_ebit numeric,
  debt_to_equity numeric,
  gross_margin numeric, operating_margin numeric, net_margin numeric,
  roic numeric,
  cap_category text check (cap_category in ('small','mid','large')),
  extra jsonb default '{}'::jsonb,       -- trykkventil for sjeldne metrikker
  unique (company_id, period_date, period_type, filing_date)
);
create index ix_fin_company_filing on financials (company_id, filing_date desc);
create index ix_fin_company_period on financials (company_id, period_date desc);

-- === Domene D – Kontekst & AI-innhold (02 §7) ================================

create table macro_context (
  id             bigint generated always as identity primary key,
  date           date not null,
  region         text not null default 'US',
  rate_level     text check (rate_level in ('low','neutral','high')),
  rate_direction text check (rate_direction in ('rising','flat','falling')),
  inflation      numeric,
  gdp_growth     numeric,
  ai_sentence    text,                   -- batch-generert kontekstsetning
  unique (date, region)
);

create table narratives (
  id                 bigint generated always as identity primary key,
  company_id         bigint not null references companies(id),
  decision_date      date not null,
  horizon_years      int  not null,
  narrative          text not null,      -- 2 setninger, ANONYMISERT (vises på kort)
  sector_sentiment   text,               -- vises på kort
  clue               text,               -- KUN reveal
  result_explanation text,               -- KUN reveal
  leak_check_passed  boolean default false, -- hard seal-precondition
  llm_model          text,
  generated_at       timestamptz default now(),
  unique (company_id, decision_date, horizon_years)
);

-- Kartoteket (v1.1, IKKE-anonymisert, nåværende snapshot). Public-read (02 §10).
create table company_profiles (
  company_id            bigint primary key references companies(id),
  one_liner             text,
  segments              jsonb,
  moat                  text,
  bull                  text,
  bear                  text,
  last_earnings_summary text,
  last_earnings_period  date,
  refreshed_at          timestamptz default now()
);

create table earnings_summaries (
  id           bigint generated always as identity primary key,
  company_id   bigint not null references companies(id),
  period_date  date not null,
  filing_date  date,
  summary      text,
  unique (company_id, period_date)
);

-- === Domene E – Spillstruktur (02 §8, eies av Curator) =======================

create table game_batches (
  id              bigint generated always as identity primary key,
  mode            text not null check (mode in ('junior','manager','realtime')),
  region          text not null default 'US',
  benchmark_index text not null default 'SP500TR',
  decision_date   date not null,         -- t0 (look-ahead-anker)
  horizon_years   int  not null,         -- H
  seed            bigint not null,       -- deterministisk kurasjon
  is_daily        boolean default false,
  daily_date      date,                  -- unik når is_daily
  difficulty      numeric,               -- alpha-spredning (matchmaking)
  curator_version text,
  curator_params  jsonb,                 -- constraints brukt (reproduserbarhet)
  -- Frosne benchmark/risikofri-størrelser (determinisme, 01 §2/§6.6).
  -- Spec-DDL-en skriver R_m/r_m, men ukvotert kolliderer de i Postgres
  -- (case-folding) — kumulative får derfor _cum-suffiks; annualiserte beholder
  -- scoring-notasjonens navn.
  r_m_cum numeric, r_m numeric, r_f_cum numeric, r_f numeric, alpha_cash numeric,
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

  -- PUBLIC-lag: nøyaktig det API-et serverer (anonymisert, uforanderlig snapshot).
  -- ALDRI navn/ticker/beløp.
  public_payload jsonb not null,

  -- Analytics-flate kopier (settes ved seal; investorprofil-spørringer):
  f_pe numeric, f_debt_to_equity numeric, f_rev_cagr numeric,
  f_sector text, f_cap text,

  -- TRUTH-lag: beregnet ved seal, KUN reveal:
  name text,
  alpha numeric,                         -- annualisert alpha (01 §2)
  ret_cum numeric, ret_ann numeric,
  event text default 'none' check (event in ('none','delisted','acquired')),
  clue text, result_explanation text,

  primary key (batch_id, card_no)
);
create index ix_batch_cards_company on batch_cards (company_id); -- Kartotek-kryssref

-- === Domene F – Bruker & analytics (02 §9) ===================================

-- INGEN hard FK til Supabase her: id = auth.uid() settes av FastAPI/Supabase,
-- og FK-en mot auth.users ligger i Supabase-only-migrasjonen (02 §10).
create table profiles (
  id              uuid primary key,
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
  is_daily      boolean not null default false, -- denormalisert for daily-unikhet
  started_at    timestamptz default now(),
  submitted_at  timestamptz,
  score         numeric, bonus numeric, hit_rate numeric,
  manager_extra jsonb                    -- TE, IR, sharpe, n_eff, korr, ex_ante (01 §7)
);
-- Dagens Runde: ett forsøk per bruker per daglig batch. Øving: fri replay.
create unique index uq_session_daily
  on game_sessions (user_id, batch_id) where is_daily;

create table decisions (
  id          bigint generated always as identity primary key,
  session_id  bigint not null references game_sessions(id) on delete cascade,
  card_no     int not null,
  choice      text not null check (choice in ('long','short','cash','skip')),
  weight      numeric,                   -- KUN Manager; null/ignorert i Junior
  response_ms int,                       -- reaksjonstid (analytics)
  created_at  timestamptz default now(),
  unique (session_id, card_no)
);

create table collections (               -- Kartoteket «Min samling»
  user_id    uuid   not null references profiles(id) on delete cascade,
  company_id bigint not null references companies(id),
  saved_at   timestamptz default now(),
  source     text check (source in ('reveal','deck','search','daily_company')),
  primary key (user_id, company_id)
);

create table decks (                     -- v1.1
  id          bigint generated always as identity primary key,
  title       text not null,
  description text,
  type        text not null check (type in ('curated','screen')),
  definition  jsonb,                     -- screen-kriterier når type='screen'
  is_active   boolean default true,
  created_at  timestamptz default now()
);

create table deck_cards (
  deck_id    bigint not null references decks(id) on delete cascade,
  company_id bigint not null references companies(id),
  position   int,
  primary key (deck_id, company_id)
);
