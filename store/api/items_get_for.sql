-- person_id
create or replace function store.items_get_for(integer,
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select i.id, i.name from store.items i
			join store.lineitems l on i.id = l.item_id
			join store.invoices v on l.invoice_id = v.id
			where v.person_id = $1
			and v.payment_date is not null
			order by name
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;
