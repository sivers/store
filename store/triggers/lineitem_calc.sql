create or replace function store.lineitem_calc() returns trigger as $$
declare
	invid integer;
	lsum numeric;
begin
	-- if not deleting, update lineitem price
	if (tg_op != 'DELETE') then
		update store.lineitems l
			set price = l.quantity * i.price
			from store.items i
			where l.item_id = i.id
			and l.id = NEW.id;
	end if;
	-- get invoice_id whether adding or deleting
	if (tg_op = 'INSERT' or tg_op = 'UPDATE') then
		invid := NEW.invoice_id;
	elsif (tg_op = 'DELETE') then
		invid := OLD.invoice_id;
	end if;
	-- whether insert|update|delete, these should work:
	select sum(price) into lsum
		from store.lineitems
		where invoice_id = invid;
	update store.invoices
		set subtotal = lsum,
			shipping = store.invoice_shipcost(invid),
			total = (lsum + store.invoice_shipcost(invid))
		where id = invid;
	return NEW;
end;
$$ language plpgsql;
drop trigger if exists lineitem_calc on store.lineitems cascade;
create trigger lineitem_calc after insert or delete or update of item_id, quantity on store.lineitems
	for each row execute procedure store.lineitem_calc();

