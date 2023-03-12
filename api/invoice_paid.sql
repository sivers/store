-- invoices.id, payment info
create function store.invoice_paid(integer, text,
	out ok boolean, out js json) as $$
declare
	err text;
begin
	update invoices
	set payment_date = now(), payment_info = $2
	where id = $1
	and payment_date is null;
	ok = true;
	js = '{}';
exception
	when others then get stacked diagnostics err = message_text;
	js = json_build_object('error', err);
	ok = false;
end;
$$ language plpgsql;
