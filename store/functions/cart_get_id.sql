-- input: person_id
-- output: invoices.id that's still open aka "cart" - null if none
create or replace function store.cart_get_id(integer, out id integer) as $$
begin
	select v.id into id
	from store.invoices v
	where person_id = $1
	and payment_date is null;
end;
$$ language plpgsql;
