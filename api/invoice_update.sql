-- invoices.id, country,
create function store.invoice_update(integer, char(2),
	out ok boolean, out js json) as $$
declare
	err text;
begin
	update invoices
	set country = $2
	where id = $1;
	ok = true;
	js = row_to_json(r) from (
		select * from store.invoice_view where id = $1
	) r;
	if js is null then
		ok = false;
		js = '{}';
	end if;
exception
	when others then get stacked diagnostics err = message_text;
	js = json_build_object('error', err);
	ok = false;
end;
$$ language plpgsql;

-- invoices.id, country, address
create function store.invoice_update(integer, char(2), text,
	out ok boolean, out js json) as $$
declare
	err text;
begin
	update invoices
	set country = $2, address = $3
	where id = $1;
	ok = true;
	js = row_to_json(r) from (
		select * from store.invoice_view where id = $1
	) r;
	if js is null then
		ok = false;
		js = '{}';
	end if;
exception
	when others then get stacked diagnostics err = message_text;
	js = json_build_object('error', err);
	ok = false;
end;
$$ language plpgsql;
