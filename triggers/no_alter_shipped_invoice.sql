create function store.no_alter_shipped_invoice() returns trigger as $$
begin
	if old.ship_date is not null 
		then raise 'no_alter_shipped_invoice';
	end if;
	if (tg_op = 'DELETE') then
		return old;
	else
		return new;
	end if;
end;
$$ language plpgsql;
create trigger no_alter_shipped_invoice
	before delete or update on invoices
	for each row execute procedure store.no_alter_shipped_invoice();

