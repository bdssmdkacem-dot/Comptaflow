create extension if not exists pgcrypto;

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '', company_name text not null default '', rc text, rc_number text, ice text,
  if_number text, tp_number text, legal_form text, address text, company_address text, city text,
  professional_phone text, phone text, email text, payment_terms text,
  activity_type text not null default 'services', locale_pref text not null default 'ar',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.clients (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  name text not null, ice text, if_number text, rc_number text, tp_number text, phone text, email text,
  address text, city text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  name text not null, description text, reference text, type text not null default 'product', unit text not null default 'unit',
  unit_price numeric(14,2) not null default 0 check (unit_price >= 0), purchase_price numeric(14,2) not null default 0 check (purchase_price >= 0),
  tax_rate numeric(5,2) not null default 0 check (tax_rate >= 0 and tax_rate <= 100), stock_managed boolean not null default false,
  stock_quantity numeric(14,3) not null default 0 check (stock_quantity >= 0), min_stock numeric(14,3) not null default 0 check (min_stock >= 0),
  active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  constraint products_type_check check (type in ('product','service'))
);
create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  client_id uuid references public.clients(id) on delete set null, invoice_number text not null, date date not null default current_date,
  total_ht numeric(14,2) not null default 0, total_tva numeric(14,2) not null default 0, total_ttc numeric(14,2) not null default 0,
  status text not null default 'draft' check (status in ('draft','issued','paid','cancelled')), pdf_url text,
  seller_name text, seller_ice text, seller_if text, seller_rc text, seller_tp text, seller_address text, seller_city text,
  seller_phone text, seller_email text, payment_terms text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.invoice_items (
  id uuid primary key default gen_random_uuid(), invoice_id uuid not null references public.invoices(id) on delete cascade,
  description text not null, quantity numeric(14,3) not null default 1 check (quantity > 0),
  unit_price numeric(14,2) not null default 0 check (unit_price >= 0), tax_rate numeric(5,2) not null default 0 check (tax_rate >= 0 and tax_rate <= 100),
  created_at timestamptz not null default now()
);
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  supplier_name text not null, description text not null, category text not null, amount_ht numeric(14,2) not null default 0 check (amount_ht >= 0),
  tax_rate numeric(5,2) not null default 0 check (tax_rate >= 0 and tax_rate <= 100), expense_date date not null default current_date,
  notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.cpu_declarations (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  period date not null, ca_encaisse numeric(14,2) not null default 0, cpu_rate numeric(5,4) not null,
  cpu_amount numeric(14,2) not null default 0, declared_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.stock_movements (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  type text not null check (type in ('purchase','sale','adjustment_in','adjustment_out')),
  quantity numeric(14,3) not null check (quantity > 0), note text, created_at timestamptz not null default now()
);

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
alter table public.products add column if not exists reference text;
alter table public.products add column if not exists type text not null default 'product';
alter table public.products add column if not exists purchase_price numeric(14,2) not null default 0;
alter table public.products add column if not exists stock_managed boolean not null default false;
alter table public.products add column if not exists stock_quantity numeric(14,3) not null default 0;
alter table public.products add column if not exists min_stock numeric(14,3) not null default 0;
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
alter table public.stock_movements enable row level security;

drop policy if exists "profiles_owner_select" on public.profiles;
drop policy if exists "profiles_owner_insert" on public.profiles;
drop policy if exists "profiles_owner_update" on public.profiles;
drop policy if exists "clients_owner_all" on public.clients;
drop policy if exists "products_owner_all" on public.products;
drop policy if exists "invoices_owner_all" on public.invoices;
drop policy if exists "expenses_owner_all" on public.expenses;
drop policy if exists "cpu_owner_all" on public.cpu_declarations;
drop policy if exists "invoice_items_owner_all" on public.invoice_items;
drop policy if exists "stock_movements_owner_all" on public.stock_movements;
create policy "profiles_owner_select" on public.profiles for select to authenticated using ((select auth.uid()) = user_id);
create policy "profiles_owner_insert" on public.profiles for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "profiles_owner_update" on public.profiles for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "clients_owner_all" on public.clients for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "products_owner_all" on public.products for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "invoices_owner_all" on public.invoices for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "expenses_owner_all" on public.expenses for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "cpu_owner_all" on public.cpu_declarations for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "invoice_items_owner_all" on public.invoice_items for all to authenticated using (exists (select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid()))) with check (exists (select 1 from public.invoices i where i.id = invoice_id and i.user_id = (select auth.uid())));
create policy "stock_movements_owner_all" on public.stock_movements for all to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

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
create index if not exists stock_movements_user_id_idx on public.stock_movements(user_id);
create index if not exists stock_movements_product_id_idx on public.stock_movements(product_id);

create or replace function public.next_invoice_number() returns text language plpgsql security definer set search_path = public as $$ declare next_number integer; begin if auth.uid() is null then raise exception 'Authentication required'; end if; perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text, 0)); select coalesce(max((substring(invoice_number from '^FAC-([0-9]+)$'))::integer), 0) + 1 into next_number from public.invoices where user_id = auth.uid() and invoice_number ~ '^FAC-[0-9]+$'; return 'FAC-' || lpad(next_number::text, 4, '0'); end; $$;
create or replace function public.client_invoice_stats(p_client_id uuid) returns table(invoice_count bigint, ca_ht numeric, encaisse_ttc numeric, restant_ttc numeric) language sql security definer set search_path = public as $$ select count(*)::bigint, coalesce(sum(total_ht),0)::numeric, coalesce(sum(case when status='paid' then total_ttc else 0 end),0)::numeric, coalesce(sum(case when status='issued' then total_ttc else 0 end),0)::numeric from public.invoices where client_id=p_client_id and user_id=auth.uid(); $$;
create or replace function public.apply_stock_movement() returns trigger language plpgsql security invoker set search_path=public as $$ declare delta numeric(14,3); begin delta := case when new.type in ('purchase','adjustment_in') then new.quantity else -new.quantity end; update public.products set stock_quantity=stock_quantity+delta, updated_at=now() where id=new.product_id and user_id=new.user_id and stock_managed=true; if not found then raise exception 'Product does not belong to the authenticated owner or stock management is disabled'; end if; if exists(select 1 from public.products where id=new.product_id and stock_quantity<0) then raise exception 'Stock quantity cannot be negative'; end if; return new; end; $$;
drop trigger if exists stock_movement_apply on public.stock_movements;
create trigger stock_movement_apply after insert on public.stock_movements for each row execute function public.apply_stock_movement();
revoke all on function public.next_invoice_number() from public, anon;
revoke all on function public.client_invoice_stats(uuid) from public, anon;
revoke all on function public.apply_stock_movement() from public;
grant execute on function public.next_invoice_number() to authenticated;
grant execute on function public.client_invoice_stats(uuid) to authenticated;