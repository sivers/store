-- person_id
create or replace function store.invoices_get_for(integer,
	out status smallint, out js json) as $$
begin
	status := 200;
	js := coalesce((
		json_agg(r) from (
			select * from store.invoice_view
			where person_id = $1
			order by id
		) r
	), '[]');
end;
$$ language plpgsql;
