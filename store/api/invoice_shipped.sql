-- invoices.id, shipment info
create or replace function store.invoice_shipped(integer, text,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	update store.invoices
	set ship_date = now(), ship_info = $2
	where id = $1
	and ship_date is null;
	select x.status, x.js into status, js
	from store.invoice_get($1) x;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;
