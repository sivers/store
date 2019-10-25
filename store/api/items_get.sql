create or replace function store.items_get(
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select * from store.items order by name
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;
