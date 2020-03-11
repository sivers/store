create or replace function store.no_alter_paid_lineitem() returns trigger as $$
declare
	paid_invoice integer;
begin
	select v.id into paid_invoice
	from store.invoices v
	where v.id = old.invoice_id
	and v.payment_date is not null;
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
drop trigger if exists no_alter_paid_lineitem on store.lineitems cascade;
create trigger no_alter_paid_lineitem before delete or update on store.lineitems
for each row execute procedure store.no_alter_paid_lineitem();
