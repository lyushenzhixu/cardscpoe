-- Trending 数据：可选方案
-- 方案一：不建新表，直接查 cards / price_summary（当前 App 已支持）
-- 方案二：用下面视图/表做“预计算”，由 cron 或 Edge Function 定期刷新，App 只读

-- 1) 热门球员视图：按价格变化排序（实时从 cards 算）
create or replace view public.trending_players_view as
select
  p.id as player_id,
  p.name,
  p.sport,
  p.team,
  p.position,
  p.headshot_url,
  c.id as card_id,
  c.current_price,
  c.price_change,
  c.image_url as card_image_url
from public.players p
join public.cards c on c.player_id = p.id
where c.current_price > 0
order by c.price_change desc nulls last, c.current_price desc
limit 50;

comment on view public.trending_players_view is 'Trending players by price_change; query this from App or Edge Function.';

-- 2) 热门系列视图：按卡牌数量/价格聚合（实时从 cards 算）
create or replace view public.popular_series_view as
select
  brand,
  set_name,
  year,
  count(*) as card_count,
  sum(current_price) as total_value
from public.cards
where brand is not null and set_name is not null
group by brand, set_name, year
order by card_count desc, total_value desc
limit 30;

comment on view public.popular_series_view is 'Popular series by card count; query this for Explore Popular Series.';

-- 3) 可选：预计算快照表（由 cron/Edge Function 每小时或每天刷新，接口更快）
create table if not exists public.trending_snapshot (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('players', 'series')),
  payload jsonb not null,
  computed_at timestamptz not null default now()
);

create index if not exists idx_trending_snapshot_kind_at
  on public.trending_snapshot (kind, computed_at desc);

comment on table public.trending_snapshot is 'Pre-computed trending data; fill via cron or Edge Function, read from App.';

-- RLS：只读
alter table public.trending_snapshot enable row level security;

drop policy if exists "public read trending_snapshot" on public.trending_snapshot;
create policy "public read trending_snapshot"
  on public.trending_snapshot for select
  using (true);
