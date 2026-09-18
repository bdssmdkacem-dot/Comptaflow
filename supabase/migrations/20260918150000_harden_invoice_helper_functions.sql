-- Security hardening for invoice helper RPCs.
-- These functions do not require elevated privileges; keep execution inside
-- the caller's RLS context to prevent cross-tenant access.
create or replace function public.client_invoice_stats(p_client_id uuid)
returns table(invoice_count bigint, ca_ht numeric, encaisse_ttc numeric, restant_ttc numeric)
language sql
security invoker
set search_path = public
as $function$
  select count(*)::bigint,
    coalesce(sum(total_ht), 0)::numeric,
    coalesce(sum(case when status = 'paid' then total_ttc else 0 end), 0)::numeric,
    coalesce(sum(case when status = 'issued' then total_ttc else 0 end), 0)::numeric
  from public.invoices
  where client_id = p_client_id and user_id = auth.uid();
$function$;

create or replace function public.next_invoice_number()
returns text
language plpgsql
security invoker
set search_path = public
as $function$
declare next_number integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text, 0));
  select coalesce(max((substring(invoice_number from '^FAC-([0-9]+)$'))::integer), 0) + 1 into next_number
  from public.invoices
  where user_id = auth.uid() and invoice_number ~ '^FAC-[0-9]+$';
  return 'FAC-' || lpad(next_number::text, 4, '0');
end;
$function$;

revoke execute on function public.client_invoice_stats(uuid) from public, anon;
grant execute on function public.client_invoice_stats(uuid) to authenticated;
revoke execute on function public.next_invoice_number() from public, anon;
grant execute on function public.next_invoice_number() to authenticated;
