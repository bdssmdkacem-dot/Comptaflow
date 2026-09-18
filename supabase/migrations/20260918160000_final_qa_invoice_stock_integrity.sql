-- Final QA: invoice ownership, duplicate numbers, immutable stock history,
-- product-linked invoice lines, and atomic stock deduction on issue.

create or replace function public.update_draft_invoice(
  p_invoice_id uuid,p_invoice_number text,p_client_id uuid,p_date date,p_items jsonb
) returns void language plpgsql security invoker set search_path=public as $
declare
  v_user_id uuid := auth.uid(); v_invoice public.invoices%rowtype;
  v_client public.clients%rowtype; v_profile public.profiles%rowtype;
  v_total_ht numeric(14,2); v_total_tva numeric(14,2); v_total_ttc numeric(14,2);
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_invoice_number is null or btrim(p_invoice_number)='' then raise exception 'Invoice number is required'; end if;
  if p_items is null or jsonb_typeof(p_items)<>'array' or jsonb_array_length(p_items)=0 then raise exception 'Invoice must contain at least one line'; end if;
  select * into v_invoice from public.invoices where id=p_invoice_id and user_id=v_user_id and status='draft' for update;
  if not found then raise exception 'Draft invoice not found or not owned by current user'; end if;
  if p_client_id is null then raise exception 'Client is required'; end if;
  select * into v_client from public.clients where id=p_client_id and user_id=v_user_id;
  if not found then raise exception 'Client not found or not owned by current user'; end if;
  select * into v_profile from public.profiles where user_id=v_user_id limit 1;
  if exists (
    select 1 from jsonb_array_elements(p_items) item
    where coalesce(btrim(item->>'description'),'')=''
       or coalesce((item->>'quantity')::numeric,0)<=0
       or coalesce((item->>'unit_price')::numeric,-1)<0
       or coalesce((item->>'tax_rate')::numeric,-1)<0
       or coalesce((item->>'tax_rate')::numeric,101)>100
       or (nullif(item->>'product_id','') is not null and not exists (
            select 1 from public.products p where p.id=(item->>'product_id')::uuid and p.user_id=v_user_id))
  ) then raise exception 'Invalid invoice line or product'; end if;
  select round(coalesce(sum((item->>'quantity')::numeric*(item->>'unit_price')::numeric),0),2),
         round(coalesce(sum((item->>'quantity')::numeric*(item->>'unit_price')::numeric*(item->>'tax_rate')::numeric/100),0),2)
    into v_total_ht,v_total_tva from jsonb_array_elements(p_items) item;
  v_total_ttc:=round(v_total_ht+v_total_tva,2);
  update public.invoices set invoice_number=btrim(p_invoice_number),client_id=p_client_id,date=p_date,
    total_ht=v_total_ht,total_tva=v_total_tva,total_ttc=v_total_ttc,
    seller_name=coalesce(nullif(btrim(v_profile.company_name),''),nullif(btrim(v_profile.full_name),'')),
    seller_ice=v_profile.ice,seller_if=v_profile.if_number,seller_rc=v_profile.rc_number,seller_tp=v_profile.tp_number,
    seller_address=v_profile.company_address,seller_city=v_profile.city,seller_phone=v_profile.phone,
    seller_email=coalesce(v_profile.email,(select email from auth.users where id=v_user_id)),
    payment_terms=v_profile.payment_terms,buyer_name=v_client.name,buyer_ice=v_client.ice,buyer_if=v_client.if_number,
    buyer_rc=v_client.rc_number,buyer_tp=v_client.tp_number,buyer_address=v_client.address,buyer_city=v_client.city,
    buyer_phone=v_client.phone,buyer_email=v_client.email,updated_at=now()
  where id=p_invoice_id and user_id=v_user_id and status='draft';
  delete from public.invoice_items where invoice_id=p_invoice_id;
  insert into public.invoice_items(invoice_id,product_id,description,quantity,unit_price,tax_rate)
  select p_invoice_id,nullif(item->>'product_id','')::uuid,btrim(item->>'description'),
         (item->>'quantity')::numeric,(item->>'unit_price')::numeric,(item->>'tax_rate')::numeric
  from jsonb_array_elements(p_items) item;
end; $;

alter table public.invoice_items
  add column if not exists product_id uuid references public.products(id) on delete set null;

create index if not exists invoice_items_product_id_idx
  on public.invoice_items(product_id);

drop policy if exists stock_movements_owner_all on public.stock_movements;
create policy stock_movements_owner_select
  on public.stock_movements for select to authenticated
  using ((select auth.uid()) = user_id);
create policy stock_movements_owner_insert
  on public.stock_movements for insert to authenticated
  with check ((select auth.uid()) = user_id);

revoke update, delete on public.stock_movements from authenticated, anon;
grant select, insert on public.stock_movements to authenticated;

create or replace function public.prevent_direct_stock_quantity_update()
returns trigger language plpgsql
set search_path = public
as $$
begin
  if new.stock_quantity is distinct from old.stock_quantity
     and coalesce(current_setting('comptaflow.stock_movement_apply', true), 'off') <> 'on' then
    raise exception 'Stock quantity can only be changed through a stock movement';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_direct_stock_quantity_update on public.products;
create trigger prevent_direct_stock_quantity_update
before update of stock_quantity on public.products
for each row execute function public.prevent_direct_stock_quantity_update();

create or replace function public.apply_stock_movement()
returns trigger language plpgsql
set search_path = public
as $$
declare delta numeric(14,3);
begin
  delta := case when new.type in ('purchase','adjustment_in') then new.quantity else -new.quantity end;
  perform set_config('comptaflow.stock_movement_apply','on',true);
  update public.products
     set stock_quantity=stock_quantity+delta, updated_at=now()
   where id=new.product_id and user_id=new.user_id and stock_managed=true;
  if not found then
    raise exception 'Product does not belong to the authenticated owner or stock management is disabled';
  end if;
  if exists (select 1 from public.products where id=new.product_id and stock_quantity<0) then
    raise exception 'Stock quantity cannot be negative';
  end if;
  return new;
end;
$$;

create or replace function public.deduct_invoice_stock_on_issue()
returns trigger language plpgsql
set search_path = public
as $$
declare item record;
begin
  if old.status <> 'draft' or new.status <> 'issued' then return new; end if;

  if exists (
    select 1
      from public.invoice_items ii
      left join public.products p on p.id=ii.product_id
     where ii.invoice_id=new.id
       and ii.product_id is not null
       and (p.id is null or p.user_id is distinct from new.user_id)
  ) then
    raise exception 'Invoice line product is invalid or not owned by invoice owner';
  end if;

  for item in
    select ii.product_id,ii.quantity,p.stock_quantity
      from public.invoice_items ii
      join public.products p on p.id=ii.product_id and p.user_id=new.user_id
     where ii.invoice_id=new.id and ii.product_id is not null and p.stock_managed=true
     for update of p
  loop
    if item.stock_quantity < item.quantity then
      raise exception 'Insufficient stock for invoice product';
    end if;
    insert into public.stock_movements(user_id,product_id,type,quantity,note)
    values(new.user_id,item.product_id,'sale',item.quantity,'Invoice '||new.invoice_number);
  end loop;
  return new;
end;
$$;

drop trigger if exists invoice_issue_stock_deduction on public.invoices;
create trigger invoice_issue_stock_deduction
after update of status on public.invoices
for each row execute function public.deduct_invoice_stock_on_issue();
