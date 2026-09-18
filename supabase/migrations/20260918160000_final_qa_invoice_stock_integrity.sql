-- Final QA: invoice ownership, duplicate numbers, immutable stock history,
-- product-linked invoice lines, and atomic stock deduction on issue.

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
