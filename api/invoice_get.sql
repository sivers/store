create function store.invoice_get(integer,
	out ok boolean, out js json) as $$
begin
	ok = true;
	js = row_to_json(r) from (
		select * from store.invoice_view where id = $1
	) r;
	if js is null then
		ok = false;
		js = json_build_object('error', 'not found');
	end if;
end;
$$ language plpgsql;
