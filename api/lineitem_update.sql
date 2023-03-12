-- lineitems.id, quantity
create function store.lineitem_update(integer, integer,
	out ok boolean, out js json) as $$
declare
	err text;
begin
	perform 1 from lineitems where id = $1;
	if not found then
		ok = false;
		js = '{}';
	elsif $2 > 0 then
		update lineitems
		set quantity = $2
		where id = $1;
		ok = true;
		js = row_to_json(r.*) from lineitems r where id = $1;
	else
		delete from lineitems where id = $1;
		ok = true;
		js = '{}';
	end if;
exception
	when others then get stacked diagnostics err = message_text;
	js = json_build_object('error', err);
	ok = false;
end;
$$ language plpgsql;
