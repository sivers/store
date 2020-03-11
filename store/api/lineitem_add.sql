-- person_id, item_id, quantity
create or replace function store.lineitem_add(integer, integer, integer,
	out status smallint, out js json) as $$
declare
	cart_id integer;
	line_id integer;
	e6 text; e7 text; e8 text; e9 text;
begin
	select id into cart_id from store.cart_get_id($1);
	if cart_id is null then
		select id into cart_id from store.cart_new_id($1);
	end if;
	select id into line_id
	from store.lineitems
	where invoice_id = cart_id
	and item_id = $2;
	if line_id is null then
		insert into store.lineitems (invoice_id, item_id, quantity)
		values (cart_id, $2, $3)
		returning id into line_id;
	else
		update store.lineitems
		set quantity = quantity + $3
		where id = line_id;
	end if;
	status := 200;
	js := row_to_json(r.*) from store.lineitems r where id = line_id;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;
