-- person_id
create function store.invoices_get_for(integer,
	out ok boolean, out js json) as $$
begin
	ok = true;
	js = coalesce((select json_agg(r) from (
		select * from store.invoice_view
		where person_id = $1
		order by id
	) r), '[]');
end;
$$ language plpgsql;
