create or replace function public.next_invoice_number()
returns text
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  n bigint;
begin
  if uid is null then raise exception 'Authentication required'; end if;
  insert into public.invoice_sequences(user_id, next_number)
  values (uid, 2)
  on conflict (user_id) do update
    set next_number = public.invoice_sequences.next_number + 1,
        updated_at = now()
  returning next_number - 1 into n;
  return 'FAC-' || to_char(current_date, 'YYYY') || '-' || lpad(n::text, 6, '0');
end;
$$;

create or replace function public.touch_client_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.client_invoice_stats(p_client_id uuid)
returns table(invoice_count bigint, ca_ht numeric, encaisse_ttc numeric, restant_ttc numeric)
language sql
security invoker
set search_path = public, pg_temp
as $$
  select
    count(*)::bigint,
    coalesce(sum(case when i.status in ('issued','paid') then i.total_ht else 0 end),0)::numeric,
    coalesce(sum(case when i.status = 'paid' then i.total_ttc else 0 end),0)::numeric,
    coalesce(sum(case when i.status = 'issued' then i.total_ttc else 0 end),0)::numeric
  from public.invoices i
  where i.client_id = p_client_id
    and i.user_id = auth.uid();
$$;
