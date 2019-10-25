-- person_id
create or replace function store.addresses_get(integer,
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select id, country, address
			from store.invoices
			where person_id = $1
			and address is not null
			order by id
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;
