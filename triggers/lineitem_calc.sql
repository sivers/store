create function store.lineitem_calc() returns trigger as $$
declare
	invid integer;
	lsum numeric;
begin
	-- if not deleting, update lineitem price
	if (tg_op != 'DELETE') then
		update lineitems
		set price = lineitems.quantity * items.price
		from items
		where lineitems.item_id = items.id
		and lineitems.id = new.id;
	end if;
	-- get invoice_id whether adding or deleting
	if (tg_op = 'INSERT' or tg_op = 'UPDATE') then
		invid := new.invoice_id;
	elsif (tg_op = 'DELETE') then
		invid := old.invoice_id;
	end if;
	-- whether insert, update, or delete, these should work:
	select sum(price) into lsum
	from lineitems
	where invoice_id = invid;
	update invoices
	set subtotal = lsum,
	shipping = store.invoice_shipcost(invid),
	total = (lsum + store.invoice_shipcost(invid))
	where id = invid;
	return new;
end;
$$ language plpgsql;
create trigger lineitem_calc
	after insert or delete or update of item_id, quantity on lineitems
	for each row execute procedure store.lineitem_calc();

