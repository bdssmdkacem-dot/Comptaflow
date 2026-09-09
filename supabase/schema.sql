create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  ice text,
  if_number text,
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
  phone text,
  created_at timestamptz not null default now()
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
  status text not null default 'draft',
  pdf_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null,
  quantity numeric(14,3) not null default 1,
  unit_price numeric(14,2) not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  date date not null default current_date,
  amount numeric(14,2) not null default 0,
  category text not null,
  created_at timestamptz not null default now()
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

alter table public.profiles enable row level security;
alter table public.clients enable row level security;
alter table public.products enable row level security;
alter table public.invoices enable row level security;
alter table public.invoice_items enable row level security;
alter table public.expenses enable row level security;
alter table public.cpu_declarations enable row level security;

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

create index if not exists clients_user_id_idx on public.clients(user_id);
create index if not exists products_user_id_idx on public.products(user_id);
create index if not exists invoices_user_id_idx on public.invoices(user_id);
create index if not exists invoices_client_id_idx on public.invoices(client_id);
create index if not exists invoice_items_invoice_id_idx on public.invoice_items(invoice_id);
create index if not exists expenses_user_id_idx on public.expenses(user_id);
create index if not exists cpu_declarations_user_id_period_idx on public.cpu_declarations(user_id, period);
