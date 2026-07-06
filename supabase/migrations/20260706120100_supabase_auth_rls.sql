-- KAP Supabase-kobling — 02_datamodell.md §10 (CP 2.1).
--
-- ALT som binder skjemaet til Supabase bor i denne ene filen: (a) FK fra
-- profiles til auth.users, (b) signup-trigger, (c) hele RLS-grensen.
-- På en lokal plain-Postgres hoppes denne over (FastAPI med service-rolle
-- eier da all skriving, og klient-direkte tilgang finnes ikke).

-- (a) profiles.id er auth.uid(); slett profilen når auth-brukeren slettes.
alter table profiles
  add constraint profiles_auth_fk
  foreign key (id) references auth.users(id) on delete cascade;

-- (b) Ny auth-bruker (også anonym) får automatisk en profilrad.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, is_anonymous)
  values (new.id, coalesce(new.is_anonymous, true))
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- (c) RLS — anonymiseringsgrensen (02 §10).
--
-- Klasse 1: klient-lesbar med «eier egen rad»-policy.
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
  ) with check (
    auth.uid() = (select user_id from game_sessions s where s.id = session_id)
  );

create policy own_collections on collections
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Klasse 1b: Kartotek-innhold er public-read VED DESIGN (navngitt nåtid).
alter table company_profiles   enable row level security;
alter table earnings_summaries enable row level security;
alter table decks              enable row level security;
alter table deck_cards         enable row level security;

create policy read_company_profiles on company_profiles for select using (true);
create policy read_earnings on earnings_summaries for select using (true);
create policy read_decks on decks for select using (is_active);
create policy read_deck_cards on deck_cards for select using (true);

-- Klasse 2: service-only. RLS PÅ og INGEN policy => kun service-rollen
-- (FastAPI) slipper til. Dette er fasit-/point-in-time-laget: én
-- feilkonfigurert klient skal ikke kunne dumpe svarene (forsvar i dybden).
alter table companies          enable row level security;
alter table index_constituents enable row level security;
alter table prices             enable row level security;
alter table index_prices       enable row level security;
alter table risk_free          enable row level security;
alter table financials         enable row level security;
alter table macro_context      enable row level security;
alter table narratives         enable row level security;
alter table game_batches       enable row level security;
alter table batch_cards        enable row level security;
