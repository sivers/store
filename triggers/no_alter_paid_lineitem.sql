create function store.no_alter_paid_lineitem() returns trigger as $$
begin
	perform invoices.id
	from invoices
	where invoices.id = old.invoice_id
	and invoices.payment_date is not null;
	if found then
		raise 'no_alter_paid_lineitem';
	end if;
	if (tg_op = 'DELETE') then
		return old;
	else
		return new;
	end if;
end;
$$ language plpgsql;
create trigger no_alter_paid_lineitem
	before delete or update on lineitems
	for each row execute procedure store.no_alter_paid_lineitem();

