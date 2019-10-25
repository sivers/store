create or replace function store.invoices_get(
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select * from store.invoice_view
			order by id
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;
