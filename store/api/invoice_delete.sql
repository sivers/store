create or replace function store.invoice_delete(integer,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	js := row_to_json(r.*) from store.invoice_view r where id = $1;
	status := 200;
	if js is null then
		status := 404;
		js := '{}';
	else
		delete from store.invoices where id = $1;
	end if;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;
