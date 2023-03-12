create function store.invoices_unshipped(
	out ok boolean, out js json) as $$
begin
	ok = true;
	js = coalesce((select json_agg(r) from (
		select * from store.invoice_view
		where payment_date is not null
		and ship_date is null
		and address is not null
		order by id
	) r), '[]');
end;
$$ language plpgsql;
