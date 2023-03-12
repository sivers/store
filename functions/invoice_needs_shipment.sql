-- invoice_id : does it need a shipment? (regardless of whether it has one or not)
create function store.invoice_needs_shipment(integer) returns boolean as $$
begin
	perform items.id
	from items
	join lineitems on items.id = lineitems.item_id
	where lineitems.invoice_id = $1
	and items.weight is not null;
	if found then
		return true;
	else
		return false;
	end if;
end;
$$ language plpgsql;
