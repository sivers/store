-- invoice_id : does it need a shipment? (regardless of whether it has one or not)
create or replace function store.invoice_needs_shipment(integer) returns boolean as $$
begin
	perform i.id
	from store.items i
	join store.lineitems l on i.id = l.item_id
	where l.invoice_id = $1
	and i.weight is not null;
	if found then
		return true;
	else
		return false;
	end if;
end;
$$ language plpgsql;
