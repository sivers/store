-- person_id
create function store.addresses_get(integer,
	out ok boolean, out js json) as $$
begin
	ok = true;
	js = coalesce((select json_agg(r) from (
		select id, country, address
		from invoices
		where person_id = $1
		and address is not null
		order by id
	) r), '[]');
end;
$$ language plpgsql;
