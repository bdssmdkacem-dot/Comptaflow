alter table if exists public.profiles
  add column if not exists company_name text not null default '',
  add column if not exists rc text,
  add column if not exists legal_form text,
  add column if not exists address text,
  add column if not exists city text,
  add column if not exists professional_phone text;
