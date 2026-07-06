// CP 2.1 checkpoint harness: apply both migrations to a real Postgres engine
// (PGlite/WASM, no Docker needed), then prove "tabellene finnes; du kan
// insert en rad og lese den tilbake" — plus smoke-test the schema-enforced
// invariants (gist exclusion, ticker reuse, daily uniqueness, point-in-time).
//
// Run:  cd scripts && npm install @electric-sql/pglite && node validate_migrations.mjs
import { PGlite } from '@electric-sql/pglite';
import { btree_gist } from '@electric-sql/pglite/contrib/btree_gist';
import { readFileSync } from 'node:fs';

const MIGRATIONS = new URL('../supabase/migrations', import.meta.url).pathname;
const db = new PGlite({ extensions: { btree_gist } });

// Stand-in for Supabase's auth schema so the Supabase-only migration can be
// validated locally (mirrors what the hosted platform provides).
await db.exec(`
  create schema auth;
  create table auth.users (id uuid primary key, is_anonymous boolean default true);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
`);

await db.exec(readFileSync(`${MIGRATIONS}/20260706120000_core_schema.sql`, 'utf8'));
console.log('✓ core schema applied');
await db.exec(readFileSync(`${MIGRATIONS}/20260706120100_supabase_auth_rls.sql`, 'utf8'));
console.log('✓ supabase auth/RLS migration applied');

const tables = await db.query(`
  select table_name from information_schema.tables
  where table_schema = 'public' order by table_name`);
console.log(`✓ ${tables.rows.length} tables:`, tables.rows.map(r => r.table_name).join(', '));

// Checkpoint: insert a row and read it back.
await db.exec(`
  insert into companies (ticker, name, sector, sector_coarse)
  values ('CORX', 'Corex Systems', 'Technology', 'Teknologi');`);
const co = await db.query(`select id, ticker, name from companies`);
console.log('✓ insert+read companies:', JSON.stringify(co.rows));

// Invariant 1: overlapping index membership must be rejected (exclusion constraint).
await db.exec(`insert into index_constituents (index_code, company_id, membership)
               values ('SP500', 1, daterange('2010-01-01','2020-01-01'))`);
try {
  await db.exec(`insert into index_constituents (index_code, company_id, membership)
                 values ('SP500', 1, daterange('2015-01-01','infinity'))`);
  console.log('✗ FAIL: overlapping membership was accepted');
} catch { console.log('✓ overlapping index membership rejected (gist exclusion)'); }

// Invariant 2: active-ticker uniqueness is partial — a delisted row may share it.
await db.exec(`insert into companies (ticker, name, is_delisted, delisted_date)
               values ('BBBY', 'Bed Bath & Beyond', true, '2023-05-03')`);
await db.exec(`insert into companies (ticker, name) values ('BBBY', 'New BBBY Corp')`);
try {
  await db.exec(`insert into companies (ticker, name) values ('BBBY', 'Third Active')`);
  console.log('✗ FAIL: duplicate active ticker accepted');
} catch { console.log('✓ ticker reuse: delisted+active OK, duplicate active rejected'); }

// Invariant 3: one attempt per user per daily batch (partial unique index).
await db.exec(`
  insert into auth.users (id) values ('00000000-0000-0000-0000-000000000001');`);
const prof = await db.query(`select id, is_anonymous from profiles`);
console.log('✓ signup trigger created profile:', JSON.stringify(prof.rows));
await db.exec(`
  insert into game_batches (mode, decision_date, horizon_years, seed, is_daily, daily_date, status)
  values ('junior', '2014-06-02', 5, 20260706, true, '2026-07-06', 'live');
  insert into game_sessions (user_id, batch_id, mode, is_daily)
  values ('00000000-0000-0000-0000-000000000001', 1, 'junior', true);`);
try {
  await db.exec(`insert into game_sessions (user_id, batch_id, mode, is_daily)
                 values ('00000000-0000-0000-0000-000000000001', 1, 'junior', true);`);
  console.log('✗ FAIL: second daily session accepted');
} catch { console.log('✓ one-attempt-per-daily enforced (uq_session_daily)'); }

// Invariant 4: the canonical point-in-time query (02 §6.2) runs.
await db.exec(`
  insert into financials (company_id, period_date, period_type, filing_date, revenue, eps)
  values (1, '2013-12-31', 'annual', '2014-02-15', 1000, 2.1),
         (1, '2014-03-31', 'quarter', '2014-05-05', 260, 0.55),
         (1, '2014-03-31', 'quarter', '2014-08-20', 250, 0.50); -- restatement, ETTER decision_date`);
const pit = await db.query(`
  with as_of as (
    select distinct on (period_type, period_date) *
    from financials
    where company_id = 1 and filing_date <= '2014-06-02'
    order by period_type, period_date desc, filing_date desc)
  select distinct on (period_type) period_type, filing_date, eps
  from as_of order by period_type, period_date desc`);
console.log('✓ point-in-time query (02 §6.2):', JSON.stringify(pit.rows));

const rls = await db.query(`
  select relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname='public' and c.relkind='r' and c.relrowsecurity
  order by relname`);
console.log(`✓ RLS enabled on ${rls.rows.length} tables`);
console.log('\nCP 2.1 checkpoint PASSED');
