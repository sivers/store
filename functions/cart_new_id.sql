-- input: person_id
-- output: new invoices.id
create function store.cart_new_id(integer, out id integer) as $$
begin
	insert into invoices (person_id, country)
	select people.id, people.country
	from people
	where people.id = $1
	returning invoices.id into id;
end;
$$ language plpgsql;
