-- ============================================================
--  FOOP TRACKER — SUPABASE SETUP
--  Run this ONCE in Supabase → SQL Editor → New query → Run
-- ============================================================

-- ---------- 1. TABLES ----------

create table if not exists public.profiles (
  id   uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('field','sales','manager')),
  name text
);

create table if not exists public.batches (
  id            bigint generated always as identity primary key,
  crop          text not null,
  location      text not null,
  plants        integer not null default 0,
  planted_date  date not null,
  created_at    timestamptz default now()
);

create table if not exists public.losses (
  id         bigint generated always as identity primary key,
  batch_id   bigint references public.batches(id) on delete cascade,
  crop       text,
  location   text,
  n          integer not null,
  week       date not null,
  logged_at  timestamptz default now()
);

create table if not exists public.weeks (
  week_date     date primary key,
  nursed        integer default 0,
  transplanted  integer default 0,
  harvest       jsonb  default '{}'::jsonb,
  updated_at    timestamptz default now()
);

create table if not exists public.sales (
  id         bigint generated always as identity primary key,
  sale_date  date not null,
  market     text not null,
  veg        text not null,
  delivered  numeric default 0,
  sold       numeric default 0,
  revenue    numeric default 0,
  voucher    text,
  notes      text,
  created_at timestamptz default now()
);

create table if not exists public.market_prices (
  market text,
  veg    text,
  price  numeric default 0,
  primary key (market, veg)
);

create table if not exists public.transport (
  market      text primary key,
  cost_per_kg numeric default 0
);

create table if not exists public.crop_yields (
  crop      text primary key,
  bad       numeric default 0,
  realistic numeric default 0,
  good      numeric default 0
);

create table if not exists public.settings (
  key   text primary key,
  value jsonb
);

-- ---------- 2. ROLE HELPER ----------

create or replace function public.user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

-- ---------- 3. ROW LEVEL SECURITY ----------

alter table public.profiles      enable row level security;
alter table public.batches       enable row level security;
alter table public.losses        enable row level security;
alter table public.weeks         enable row level security;
alter table public.sales         enable row level security;
alter table public.market_prices enable row level security;
alter table public.transport     enable row level security;
alter table public.crop_yields   enable row level security;
alter table public.settings      enable row level security;

-- Everyone can read their own profile
drop policy if exists profiles_self on public.profiles;
create policy profiles_self on public.profiles
  for select using (id = auth.uid());

-- PRODUCTION DATA: field + manager can write, sales can read
do $$
declare t text;
begin
  foreach t in array array['batches','losses','weeks','crop_yields','settings']
  loop
    execute format('drop policy if exists %I_read on public.%I', t, t);
    execute format($f$create policy %I_read on public.%I
      for select using (public.user_role() in ('field','sales','manager'))$f$, t, t);

    execute format('drop policy if exists %I_write on public.%I', t, t);
    execute format($f$create policy %I_write on public.%I
      for all using (public.user_role() in ('field','manager'))
      with check (public.user_role() in ('field','manager'))$f$, t, t);
  end loop;
end $$;

-- SALES DATA: only sales + manager. The field role cannot read this at all.
do $$
declare t text;
begin
  foreach t in array array['sales','market_prices','transport']
  loop
    execute format('drop policy if exists %I_rw on public.%I', t, t);
    execute format($f$create policy %I_rw on public.%I
      for all using (public.user_role() in ('sales','manager'))
      with check (public.user_role() in ('sales','manager'))$f$, t, t);
  end loop;
end $$;

-- ---------- 4. REFERENCE DATA ----------
-- Yields per plant (kg) — adjusted for Sierra Leone field conditions.
insert into public.crop_yields (crop, bad, realistic, good) values
  ('Tomato',              1.5, 3.5, 5.5),
  ('Hot Pepper',          0.5, 1.2, 2.5),
  ('African Hot Pepper',  0.5, 1.2, 2.5),
  ('Habanero',            0.4, 1.0, 2.0),
  ('Local Hot Pepper',    0.6, 1.5, 3.0),
  ('Sweet Pepper',        0.8, 1.8, 3.0),
  ('Eggplant',            1.0, 2.0, 3.5),
  ('Garden Egg',          1.2, 2.5, 4.0),
  ('Cucumber',            1.0, 2.0, 3.5),
  ('Okra',                0.3, 0.6, 1.0),
  ('Krain Krain',         0.2, 0.4, 0.6),
  ('Carrot',              0.05,0.1, 0.15),
  ('Cabbage',             0.4, 0.8, 1.2)
on conflict (crop) do nothing;

-- Transport cost per kg delivered
insert into public.transport (market, cost_per_kg) values
  ('TormaBum', 0), ('Bo', 3.5), ('Waterloo', 7.6)
on conflict (market) do nothing;

-- Market prices (NLE per kg). 0 = not sold in that market.
insert into public.market_prices (market, veg, price) values
  ('TormaBum','Tomato',13.6),('TormaBum','Okra',26.5),('TormaBum','Local Hot Pepper',36.8),
  ('TormaBum','Habanero Hot Pepper',42.7),('TormaBum','Carrot',27.3),('TormaBum','Cucumber',7.0),
  ('TormaBum','Garden Eggs',1.8),('TormaBum','Eggplant',2.3),('TormaBum','Krainkrain',10),
  ('TormaBum','Cabbage',0),('TormaBum','Green Pepper',0),
  ('Bo','Tomato',0),('Bo','Okra',52.9),('Bo','Local Hot Pepper',51.5),
  ('Bo','Habanero Hot Pepper',102.3),('Bo','Carrot',0),('Bo','Cucumber',5.9),
  ('Bo','Garden Eggs',12.8),('Bo','Eggplant',0),('Bo','Krainkrain',14),
  ('Bo','Cabbage',0),('Bo','Green Pepper',0),
  ('Waterloo','Tomato',0),('Waterloo','Okra',0),('Waterloo','Local Hot Pepper',73.5),
  ('Waterloo','Habanero Hot Pepper',85.5),('Waterloo','Carrot',0),('Waterloo','Cucumber',23.5),
  ('Waterloo','Garden Eggs',20.1),('Waterloo','Eggplant',0),('Waterloo','Krainkrain',20),
  ('Waterloo','Cabbage',0),('Waterloo','Green Pepper',212.8)
on conflict (market, veg) do nothing;

-- Dashboard targets
insert into public.settings (key, value) values
  ('targets', '{"prod":350,"nursery":175}'::jsonb)
on conflict (key) do nothing;

-- ============================================================
--  NEXT STEP — CREATE ONE ACCOUNT PER PERSON
--
--  1) Supabase -> Authentication -> Users -> "Add user"
--     Turn "Auto Confirm User" ON.
--     Use each person's REAL email so password resets work.
--     Password: minimum 6 characters.
--
--       calvin@foop.org     -> manager
--       karen@foop.org      -> manager
--       <sales colleague>   -> sales
--       <field staff>       -> field
--
--  2) Copy each user's UID from the users list, then run:
--
--     insert into public.profiles (id, role, name) values
--       ('PASTE-CALVIN-UID', 'manager', 'Calvin'),
--       ('PASTE-KAREN-UID',  'manager', 'Karen'),
--       ('PASTE-SALES-UID',  'sales',   'Sales colleague'),
--       ('PASTE-FIELD-UID',  'field',   'Field staff');
--
--  TO ADD SOMEONE LATER: create the user, then insert one profiles row.
--  TO CHANGE SOMEONE'S ROLE:
--     update public.profiles set role = 'manager' where id = 'THEIR-UID';
--  TO REMOVE ACCESS: delete the user in Authentication -> Users.
-- ============================================================
