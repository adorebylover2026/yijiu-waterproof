-- 一久防水 PWA 雲端資料表設定
-- 在 Supabase Dashboard > SQL Editor 執行整段。
create table if not exists public.estimates (
  id uuid primary key,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  payload jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.estimates enable row level security;
drop policy if exists "Users can read own estimates" on public.estimates;
drop policy if exists "Users can insert own estimates" on public.estimates;
drop policy if exists "Users can update own estimates" on public.estimates;
drop policy if exists "Users can delete own estimates" on public.estimates;
create policy "Users can read own estimates" on public.estimates for select using (auth.uid() = user_id);
create policy "Users can insert own estimates" on public.estimates for insert with check (auth.uid() = user_id);
create policy "Users can update own estimates" on public.estimates for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users can delete own estimates" on public.estimates for delete using (auth.uid() = user_id);
create index if not exists estimates_user_updated_idx on public.estimates(user_id, updated_at desc);
