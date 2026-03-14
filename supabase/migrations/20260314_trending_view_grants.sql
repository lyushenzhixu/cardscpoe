-- Ensure app client roles can read trending views.
grant select on public.trending_players_view to anon, authenticated;
grant select on public.popular_series_view to anon, authenticated;
