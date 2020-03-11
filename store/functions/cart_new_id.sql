-- input: person_id
-- output: new invoices.id
create or replace function store.cart_new_id(integer, out id integer) as $$
begin
	insert into store.invoices (person_id, country)
	select p.id, p.country
	from peeps.people p
	where p.id = $1
	returning store.invoices.id into id;
end;
$$ language plpgsql;
