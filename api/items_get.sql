create function store.items_get(
	out ok boolean, out js json) as $$
begin
	ok = true;
	js = coalesce((select json_agg(r) from (
		select * from items order by name
	) r), '[]');
end;
$$ language plpgsql;
