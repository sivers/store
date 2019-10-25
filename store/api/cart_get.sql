-- person_id
create or replace function store.cart_get(integer,
	out status smallint, out js json) as $$
declare
	cart_id integer;
begin
	select id into cart_id from store.cart_get_id($1);
	if cart_id is null then
		status := 404;
		js := '{}';
	else
		status := 200;
		js := row_to_json(r) from (
			select * from store.invoice_view where id = cart_id
		) r;
	end if;
end;
$$ language plpgsql;
