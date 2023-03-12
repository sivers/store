-- person_id
create function store.cart_get(integer,
	out ok boolean, out js json) as $$
declare
	cart_id integer;
begin
	select id into cart_id from store.cart_get_id($1);
	if cart_id is null then
		ok = false;
		js = json_build_object('error', 'not found');
	else
		ok = true;
		js = row_to_json(r) from (
			select * from store.invoice_view where id = cart_id
		) r;
	end if;
end;
$$ language plpgsql;
