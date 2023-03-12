create function store.invoices_get(
	out ok boolean, out js json) as $$
begin
	ok = true;
	js = coalesce((select json_agg(r) from (
		select * from store.invoice_view
		order by id
	) r), '[]');
end;
$$ language plpgsql;
