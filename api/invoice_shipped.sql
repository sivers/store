-- invoices.id, shipment info
create function store.invoice_shipped(integer, text,
	out ok boolean, out js json) as $$
declare
	err text;
begin
	update invoices
	set ship_date = now(), ship_info = $2
	where id = $1
	and ship_date is null;
	ok = true;
	js = '{}';
exception
	when others then get stacked diagnostics err = message_text;
	js = json_build_object('error', err);
	ok = false;
end;
$$ language plpgsql;
