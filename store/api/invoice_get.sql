create or replace function store.invoice_get(integer,
	out status smallint, out js json) as $$
begin
	js := row_to_json(r) from (
		select * from store.invoice_view where id = $1
	) r;
	status := 200;
	if js is null then
		js := '{}';
		status := 404;
	end if;
end;
$$ language plpgsql;
