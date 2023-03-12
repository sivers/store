-- output: new invoices.id
create function store.cart_new_id(_person_id integer, out id integer) as $$
	insert into invoices (person_id, country)
	select people.id, people.country
	from people
	where people.id = $1
	returning invoices.id;
$$ language sql;
