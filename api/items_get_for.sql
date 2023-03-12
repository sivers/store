-- person_id
create function store.items_get_for(integer,
	out ok boolean, out js json) as $$
begin
	ok = true;
	js = coalesce((select json_agg(r) from (
		select i.id, i.name from items i
		join lineitems l on i.id = l.item_id
		join invoices v on l.invoice_id = v.id
		where v.person_id = $1
		and v.payment_date is not null
		order by name
	) r), '[]');
end;
$$ language plpgsql;
