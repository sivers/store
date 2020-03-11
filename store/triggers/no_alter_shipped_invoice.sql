create or replace function store.no_alter_shipped_invoice() returns trigger as $$
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
drop trigger if exists no_alter_shipped_invoice on store.invoices cascade;
create trigger no_alter_shipped_invoice before delete or update on store.invoices
for each row execute procedure store.no_alter_shipped_invoice();
