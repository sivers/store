-- input: invoice_id output: numeric cost of shipping current lineitems
create or replace function store.invoice_shipcost(integer, out cost numeric) as $$
begin
	select store.shipcost(v.country, sum(coalesce(i.weight, 0) * l.quantity)) into cost
	from store.invoices v
	join store.lineitems l on v.id = l.invoice_id
	join store.items i on l.item_id = i.id
	where v.id = $1
	group by v.country;
end;
$$ language plpgsql;
