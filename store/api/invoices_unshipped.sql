create or replace function store.invoices_unshipped(
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select * from store.invoice_view
			where payment_date is not null
			and ship_date is null
			and address is not null
			order by id
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;
