-- person_id, item_id, quantity
create function store.lineitem_add(integer, integer, integer,
	out ok boolean, out js json) as $$
declare
	cart_id integer;
	line_id integer;
	err text;
begin
	select id into cart_id from store.cart_get_id($1);
	if cart_id is null then
		select id into cart_id from store.cart_new_id($1);
	end if;
	select id into line_id
	from lineitems
	where invoice_id = cart_id
	and item_id = $2;
	if line_id is null then
		insert into lineitems (invoice_id, item_id, quantity)
		values (cart_id, $2, $3)
		returning id into line_id;
	else
		update lineitems
		set quantity = quantity + $3
		where id = line_id;
	end if;
	ok = true;
	js = row_to_json(r.*) from lineitems r where id = line_id;
exception
	when others then get stacked diagnostics err = message_text;
	js = json_build_object('error', err);
	ok = false;
end;
$$ language plpgsql;
