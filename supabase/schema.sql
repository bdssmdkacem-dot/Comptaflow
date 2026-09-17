create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  company_name text not null default '',
  rc text,
  rc_number text,
  ice text,
  if_number text,
  tp_number text,
  legal_form text,
  address text,
  company_address text,
  city text,
  professional_phone text,
  phone text,
  email text,
  payment_terms text,
  activity_type text not null default 'services',
  locale_pref text not null default 'ar',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  ice text,
  if_number text,
  rc_number text,
  tp_number text,
  phone text,
  email text,
  address text,
  city text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  unit text not null default 'unit',
  unit_price numeric(14,2) not null default 0 check (unit_price >= 0),
  tax_rate numeric(5,2) not null default 0 check (tax_rate >= 0 and tax_rate <= 100),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  client_id uuid references public.clients(id) on delete set null,
  invoice_number text not null,
  date date not null default current_date,
  total_ht numeric(14,2) not null default 0,
  total_tva numeric(14,2) not null default 0,
  total_ttc numeric(14,2) not null default 0,
  status text not null default 'draft' check (status in ('draft','issued','paid','cancelled')),
  pdf_url text,
  seller_name text,
  seller_ice text,
  seller_if text,
  seller_rc text,
  seller_tp text,
  seller_address text,
  seller_city text,
  seller_phone text,
  seller_email text,
  payment_terms text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity numeric(14,3) not null default 1 check (quantity > 0),
  unit_price numeric(14,2) not null default 0 check (unit_price >= 0),
  tax_rate numeric(5,2) not null default 0 check (tax_rate >= 0 and tax_rate <= 100),
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  supplier_name text not null,
  description text not null,
  category text not null,
  amount_ht numeric(14,2) not null default 0 check (amount_ht >= 0),
  tax_rate numeric(5,2) not null default 0 check (tax_rate >= 0 and tax_rate <= 100),
  expense_date date not null default current_date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cpu_declarations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  period date not null,
  ca_encaisse numeric(14,2) not null default 0,
  cpu_rate numeric(5,4) not null,
  cpu_amount numeric(14,2) not null default 0,
  declared_at timestamptz,
  created_at timestamptz not null default now()
);

-- Bring an existing database created from an older schema forward safely.
alter table public.profiles add column if not exists rc_number text;
alter table public.profiles add column if not exists tp_number text;
alter table public.profiles add column if not exists company_address text;
alter table public.profiles add column if not exists phone text;
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists payment_terms text;

alter table public.clients add column if not exists if_number text;
alter table public.clients add column if not exists rc_number text;
alter table public.clients add column if not exists tp_number text;
alter table public.clients add column if not exists email text;
alter table public.clients add column if not exists address text;
alter table public.clients add column if not exists city text;
alter table public.clients add column if not exists updated_at timestamptz not null default now();

alter table public.invoices add column if not exists seller_name text;
alter table public.invoices add column if not exists seller_ice text;
alter table public.invoices add column if not exists seller_if text;
alter table public.invoices add column if not exists seller_rc text;
alter table public.invoices add column if not exists seller_tp text;
alter table public.invoices add column if not exists seller_address text;
alter table public.invoices add column if not exists seller_city text;
alter table public.invoices add column if not exists seller_phone text;
alter table public.invoices add column if not exists seller_email text;
alter table public.invoices add column if not exists payment_terms text;
alter table public.invoices add column if not exists updated_at timestamptz not null default now();

alter table public.invoice_items add column if not exists tax_rate numeric(5,2) not null default 0;

alter table public.expenses add column if not exists supplier_name text not null default '';
alter table public.expenses add column if not exists description text not null default '';
alter table public.expenses add column if not exists amount_ht numeric(14,2) not null default 0;
alter table public.expenses add column if not exists tax_rate numeric(5,2) not null default 0;
alter table public.expenses add column if not exists expense_date date not null default current_date;
alter table public.expenses add column if not exists notes text;
alter table public.expenses add column if not exists updated_at timestamptz not null default now();

alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.products enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.expenses enable row level security;
alter table public.cpu_declarations enable row level security;

drop policy if exists "profiles_owner_select" on public.profiles;
drop policy if exists "profiles_owner_insert" on public.profiles;
drop policy if exists "profiles_owner_update" on public.profiles;
drop policy if exists "clients_owner_all" on public.clients;
drop policy if exists "products_owner_all" on public.products;
drop policy if exists "invoices_owner_all" on public.invoices;
drop policy if exists "expenses_owner_all" on public.expenses;
drop policy if exists "cpu_owner_all" on public.cpu_declarations;
drop policy if exists "invoice_items_owner_all" on public.invoice_items;

create policy "profiles_owner_select" on public.profiles for select to authenticated using ((select auth.uid()) = user_id);
create policy "profiles_owner_insert" on public.profiles for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "profiles_owner_update" on public.profiles for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "clients_owner_all" on public.clients for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "products_owner_all" on public.products for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "invoices_owner_all" on public.invoices for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "expenses_owner_all" on public.expenses for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "cpu_owner_all" on public.cpu_declarations for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "invoice_items_owner_all" on public.invoice_items for all to authenticated
using (exists (select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid())))
with check (exists (select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid())));

create unique index if not exists invoices_user_invoice_number_uidx on public.invoices(user_id, invoice_number);
create index if not exists clients_user_id_idx on public.clients(user_id);
create index if not exists clients_user_name_idx on public.clients(user_id, name);
create index if not exists products_user_id_idx on public.products(user_id);
create index if not exists invoices_user_id_idx on public.invoices(user_id);
create index if not exists invoices_client_id_idx on public.invoices(client_id);
create index if not exists invoices_user_date_idx on public.invoices(user_id, date desc);
create index if not exists invoice_items_invoice_id_idx on public.invoice_items(invoice_id);
create index if not exists expenses_user_id_idx on public.expenses(user_id);
create index if not exists expenses_user_date_idx on public.expenses(user_id, expense_date desc);
create index if not exists cpu_declarations_user_id_period_idx on public.cpu_declarations(user_id, period);

create or replace function public.next_invoice_number()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  next_number integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text, 0));

  select coalesce(max((substring(invoice_number from '^FAC-([0-9]+)$'))::integer), 0) + 1
    into next_number
  from public.invoices
  where user_id = auth.uid()
    and invoice_number ~ '^FAC-[0-9]+$';

  return 'FAC-' || lpad(next_number::text, 4, '0');
end;
$$;

grant execute on function public.next_invoice_number() to authenticated;

create or replace function public.client_invoice_stats(p_client_id uuid)
returns table(invoice_count bigint, ca_ht numeric, encaisse_ttc numeric, restant_ttc numeric)
language sql
security definer
set search_path = public
as $$
  select
    count(*)::bigint,
    coalesce(sum(total_ht), 0)::numeric,
    coalesce(sum(case when status = 'paid' then total_ttc else 0 end), 0)::numeric,
    coalesce(sum(case when status = 'issued' then total_ttc else 0 end), 0)::numeric
  from public.invoices
  where client_id = p_client_id
    and user_id = auth.uid();
$$;

grant execute on function public.client_invoice_stats(uuid) to authenticated;
