-- 一久防水 CRM + 兩人共用公司資料庫升級（在 Supabase SQL Editor 執行一次）
create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique default upper(substr(encode(gen_random_bytes(8),'hex'),1,10)),
  created_by uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.org_members (
  org_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member')),
  joined_at timestamptz not null default now(),
  primary key (org_id,user_id)
);

create or replace function public.is_org_member(p_org uuid)
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.org_members m where m.org_id=p_org and m.user_id=auth.uid()); $$;

create or replace function public.create_company(p_name text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_org public.organizations;
begin
  if auth.uid() is null then raise exception '請先登入'; end if;
  if exists(select 1 from public.org_members where user_id=auth.uid()) then raise exception '此帳號已加入公司'; end if;
  insert into public.organizations(name,created_by) values (trim(p_name),auth.uid()) returning * into v_org;
  insert into public.org_members(org_id,user_id,role) values(v_org.id,auth.uid(),'owner');
  return jsonb_build_object('id',v_org.id,'name',v_org.name,'invite_code',v_org.invite_code);
end; $$;

create or replace function public.join_company(p_code text)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare v_org public.organizations;
begin
  if auth.uid() is null then raise exception '請先登入'; end if;
  if exists(select 1 from public.org_members where user_id=auth.uid()) then raise exception '此帳號已加入公司'; end if;
  select * into v_org from public.organizations where invite_code=upper(trim(p_code));
  if not found then raise exception '邀請碼不存在'; end if;
  insert into public.org_members(org_id,user_id,role) values(v_org.id,auth.uid(),'member') on conflict do nothing;
  return jsonb_build_object('id',v_org.id,'name',v_org.name);
end; $$;

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(), org_id uuid not null references public.organizations(id) on delete cascade,
  name text not null, customer_type text default '一般屋主', contact_person text, phone text, email text, line_id text,
  address text, source text, notes text, created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(), org_id uuid not null references public.organizations(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null, name text not null, address text,
  status text not null default '待勘查' check(status in ('待勘查','待報價','已報價','已簽約','施工中','待收款','已完工','已取消')),
  start_date date, end_date date, warranty_years numeric(4,1) default 0, warranty_until date,
  description text, created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(), org_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade, amount numeric(12,2) not null check(amount>0),
  paid_at date not null default current_date, payment_type text not null default '工程款', method text, note text,
  created_by uuid not null default auth.uid() references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.followups (
  id uuid primary key default gen_random_uuid(), org_id uuid not null references public.organizations(id) on delete cascade,
  project_id uuid references public.projects(id) on delete cascade, customer_id uuid references public.customers(id) on delete cascade,
  due_date date not null, followup_type text not null default '客戶回訪', note text, status text not null default '待處理' check(status in ('待處理','已完成')),
  created_by uuid not null default auth.uid() references auth.users(id), created_at timestamptz not null default now()
);

alter table public.estimates add column if not exists org_id uuid references public.organizations(id) on delete cascade;
alter table public.estimates add column if not exists customer_id uuid references public.customers(id) on delete set null;
alter table public.estimates add column if not exists project_id uuid references public.projects(id) on delete set null;

alter table public.organizations enable row level security;
alter table public.org_members enable row level security;
alter table public.customers enable row level security;
alter table public.projects enable row level security;
alter table public.payments enable row level security;
alter table public.followups enable row level security;

drop policy if exists org_read on public.organizations;
create policy org_read on public.organizations for select using (public.is_org_member(id));
drop policy if exists members_read on public.org_members;
create policy members_read on public.org_members for select using (public.is_org_member(org_id));

do $$ declare t text; begin
 foreach t in array array['customers','projects','payments','followups'] loop
  execute format('drop policy if exists %I on public.%I', t||'_org_all', t);
  execute format('create policy %I on public.%I for all using (public.is_org_member(org_id)) with check (public.is_org_member(org_id))', t||'_org_all', t);
 end loop;
end $$;

drop policy if exists estimates_org_read on public.estimates;
create policy estimates_org_read on public.estimates for select using (auth.uid()=user_id or public.is_org_member(org_id));
drop policy if exists estimates_org_insert on public.estimates;
create policy estimates_org_insert on public.estimates for insert with check (auth.uid()=user_id and (org_id is null or public.is_org_member(org_id)));
drop policy if exists estimates_org_update on public.estimates;
create policy estimates_org_update on public.estimates for update using (auth.uid()=user_id or public.is_org_member(org_id)) with check ((auth.uid()=user_id) or public.is_org_member(org_id));
drop policy if exists estimates_org_delete on public.estimates;
create policy estimates_org_delete on public.estimates for delete using (auth.uid()=user_id or public.is_org_member(org_id));

revoke all on function public.create_company(text) from public;
revoke all on function public.join_company(text) from public;
grant execute on function public.create_company(text) to authenticated;
grant execute on function public.join_company(text) to authenticated;
grant select on public.organizations, public.org_members to authenticated;
grant select,insert,update,delete on public.customers,public.projects,public.payments,public.followups to authenticated;
create index if not exists customers_org_idx on public.customers(org_id,name);
create index if not exists projects_org_idx on public.projects(org_id,status);
create index if not exists payments_project_idx on public.payments(project_id,paid_at desc);
create index if not exists followups_org_due_idx on public.followups(org_id,due_date,status);
create index if not exists estimates_org_updated_idx on public.estimates(org_id,updated_at desc);
