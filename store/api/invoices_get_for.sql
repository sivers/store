-- person_id
create or replace function store.invoices_get_for(integer,
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select * from store.invoice_view
		where person_id = $1
		order by id
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;
