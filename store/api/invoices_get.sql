create or replace function store.invoices_get(
	out status smallint, out js json) as $$
begin
	status := 200;
	js := coalesce((
		json_agg(r) from (
			select * from store.invoice_view
			order by id
		) r
	), '[]');
end;
$$ language plpgsql;
