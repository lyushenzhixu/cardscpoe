-- CardScope schema bootstrap
-- Run with: supabase db push

create extension if not exists "pgcrypto";

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sport text not null check (sport in ('NBA', 'MLB', 'NFL', 'Soccer')),
  team text,
  position text,
  headshot_url text,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cards (
  id uuid primary key default gen_random_uuid(),
  player_id uuid references public.players(id) on delete set null,
  player_name text not null,
  team text not null,
  position text not null,
  sport text not null check (sport in ('NBA', 'MLB', 'NFL', 'Soccer')),
  brand text not null,
  set_name text not null,
  year text not null,
  card_number text not null,
  parallel text not null,
  is_rookie boolean not null default false,
  raw_price_low integer not null default 0,
  raw_price_high integer not null default 0,
  psa9_price_low integer not null default 0,
  psa9_price_high integer not null default 0,
  psa10_price_low integer not null default 0,
  psa10_price_high integer not null default 0,
  current_price integer not null default 0,
  price_change double precision not null default 0,
  confidence double precision not null default 90,
  grade text,
  image_url text,
  headshot_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.prices (
  id uuid primary key default gen_random_uuid(),
  card_id uuid references public.cards(id) on delete cascade,
  condition text not null,
  sale_price numeric(10, 2) not null,
  sale_date date not null default current_date,
  source text not null,
  source_url text,
  listing_title text,
  created_at timestamptz not null default now()
);

create table if not exists public.price_summary (
  card_id uuid references public.cards(id) on delete cascade,
  condition text not null,
  avg_price_30d numeric(10, 2),
  median_price_30d numeric(10, 2),
  min_price_30d numeric(10, 2),
  max_price_30d numeric(10, 2),
  total_sales_30d integer not null default 0,
  price_trend_pct numeric(6, 2) not null default 0,
  last_updated timestamptz not null default now(),
  primary key (card_id, condition)
);

create table if not exists public.user_collections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null,
  card_id uuid not null references public.cards(id) on delete cascade,
  added_at timestamptz not null default now(),
  notes text
);

create table if not exists public.scan_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  card_id uuid references public.cards(id) on delete set null,
  scanned_at timestamptz not null default now(),
  image_url text,
  extracted_text text
);

create index if not exists idx_cards_player_name on public.cards using gin (to_tsvector('simple', player_name));
create index if not exists idx_cards_series on public.cards (brand, set_name, year);
create index if not exists idx_prices_card_date on public.prices (card_id, sale_date desc);
create index if not exists idx_scan_history_user on public.scan_history (user_id, scanned_at desc);

alter table public.players enable row level security;
alter table public.cards enable row level security;
alter table public.prices enable row level security;
alter table public.price_summary enable row level security;
alter table public.user_collections enable row level security;
alter table public.scan_history enable row level security;

drop policy if exists "public read cards" on public.cards;
create policy "public read cards"
on public.cards for select
using (true);

drop policy if exists "public read players" on public.players;
create policy "public read players"
on public.players for select
using (true);

drop policy if exists "public read prices" on public.prices;
create policy "public read prices"
on public.prices for select
using (true);

drop policy if exists "public read price_summary" on public.price_summary;
create policy "public read price_summary"
on public.price_summary for select
using (true);
