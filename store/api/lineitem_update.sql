-- lineitems.id, quantity
create or replace function store.lineitem_update(integer, integer,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	perform 1 from store.lineitems where id = $1;
	if not found then
		status := 404;
		js := '{}';
	elsif $2 > 0 then
		update store.lineitems
		set quantity = $2
		where id = $1;
		status := 200;
		js := row_to_json(r.*) from store.lineitems r where id = $1;
	else
		delete from store.lineitems where id = $1;
		status := 200;
		js := '{}';
	end if;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;
