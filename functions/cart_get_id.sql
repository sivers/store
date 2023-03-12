-- output: invoices.id that's still open - AKA "cart" - null if none
create function store.cart_get_id(_person_id integer, out id integer) as $$
	select id
	from invoices 
	where person_id = $1
	and payment_date is null;
$$ language sql;
