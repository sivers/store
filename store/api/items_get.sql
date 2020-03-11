create or replace function store.items_get(
	out status smallint, out js json) as $$
begin
	status := 200;
	js := coalesce((
		json_agg(r) from (
			select * from store.items order by name
		) r
	), '[]');
end;
$$ language plpgsql;
