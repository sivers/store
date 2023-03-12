-- input: invoice_id output: numeric cost of shipping current lineitems
create function store.invoice_shipcost(integer, out cost numeric) as $$
begin
	select store.shipcost(v.country, sum(coalesce(i.weight, 0) * l.quantity)) into cost
	from invoices
	join lineitems on invoices.id = lineitems.invoice_id
	join items on lineitems.item_id = items.id
	where invoices.id = $1
	group by invoices.country;
end;
$$ language plpgsql;
