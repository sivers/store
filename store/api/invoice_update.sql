-- invoices.id, country,
create or replace function store.invoice_update(integer, char(2),
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	update store.invoices
	set country = $2
	where id = $1;
	status := 200;
	js := row_to_json(r) from (
		select * from store.invoice_view where id = $1
	) r;
	if js is null then
		status := 404;
		js := '{}';
	end if;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;

-- invoices.id, country, address
create or replace function store.invoice_update(integer, char(2), text,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	update store.invoices
	set country = $2, address = $3
	where id = $1;
	status := 200;
	js := row_to_json(r) from (
		select * from store.invoice_view where id = $1
	) r;
	if js is null then
		status := 404;
		js := '{}';
	end if;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;
