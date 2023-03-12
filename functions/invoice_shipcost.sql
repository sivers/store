-- input: invoice_id output: numeric cost of shipping current lineitems
create function store.invoice_shipcost(_invoice_id integer, out cost numeric) as $$
	select store.shipcost(invoices.country, sum(coalesce(items.weight, 0) * lineitems.quantity))
	from invoices
	join lineitems on invoices.id = lineitems.invoice_id
	join items on lineitems.item_id = items.id
	where invoices.id = $1
	group by invoices.country;
$$ language sql;
