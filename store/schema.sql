BEGIN;
set client_min_messages to error;
set client_encoding = 'UTF8';
drop schema if exists store cascade;
create schema store;
set search_path = store;

create table items (
	id serial primary key,
	name text not null unique,
	price numeric,
	weight numeric
);

create table invoices (
	id serial primary key,
	person_id integer not null references people(id),
	order_date date not null default current_date,
	payment_date date,
	payment_info text,
	subtotal numeric,
	shipping numeric,
	total numeric,
	country char(2) references countries(code),
	address text,
	ship_date date,
	ship_info text
);
create index on invoices(person_id);
create index unshipped on invoices(payment_date, ship_date, address);

create table lineitems (
	id serial primary key,
	invoice_id integer not null references invoices(id) on delete cascade,
	item_id integer not null references items(id) on delete restrict,
	quantity smallint not null default 1 check (quantity > 0),
	price numeric,
	unique(invoice_id, item_id)
);
create index on lineitems(invoice_id);

create table shipchart (
	id serial primary key,
	country char(2) references countries(code),
	weight numeric not null, -- up to this (invoice.weight <= shipchart.weight)
	cost numeric not null
);
create index on shipchart(country, weight);



drop view if exists store.invoice_view cascade;
create view store.invoice_view as
	select v.id,
	v.person_id,
	p.name,
	v.order_date,
	v.payment_date,
	v.payment_info,
	v.subtotal,
	v.shipping,
	v.total,
	v.country,
	v.address,
	v.ship_date,
	v.ship_info, (
		select json_agg(ll) as lineitems from (
			select l.id, l.item_id, i.name, l.quantity, l.price
			from store.lineitems l
			join store.items i on l.item_id = i.id
			where l.invoice_id = v.id
		) ll
	)
	from store.invoices v
	join people p on v.person_id = p.id;


-- invoice_id : does it need a shipment? (regardless of whether it has one or not)
create or replace function store.invoice_needs_shipment(integer) returns boolean as $$
begin
	perform i.id
	from items i
	join lineitems l on i.id = l.item_id
	where l.invoice_id = $1
	and i.weight is not null;
	if found then
		return true;
	else
		return false;
	end if;
end;
$$ language plpgsql;


-- input: invoice_id output: numeric cost of shipping current lineitems
create or replace function store.invoice_shipcost(integer, out cost numeric) as $$
begin
	select shipcost(v.country, sum(coalesce(i.weight, 0) * l.quantity)) into cost
	from invoices v
	join lineitems l on v.id = l.invoice_id
	join items i on l.item_id = i.id
	where v.id = $1
	group by v.country;
end;
$$ language plpgsql;


-- input: country, weight output: numeric cost
create or replace function store.shipcost(char(2), numeric) returns numeric as $$
declare
	-- query into this. return when not null.
	c numeric;
begin
	-- zero weight = zero cost
	if $2 = 0 then
		return 0;
	end if;
	-- weights out of range? $1000  :-)
	if ($2 < 0) or ($2 > 999) then
		return 1000;
	end if;
	-- is specific country in shipchart?
	select cost into c from shipchart
	where country = $1
	and weight >= $2
	order by cost asc limit 1;
	if c is not null then
		return c;
	end if;
	-- if country didn't match, null means "rest of world"
	select cost into c from shipchart
	where country is null
	and weight >= $2
	order by cost asc limit 1;
	if c is not null then
		return c;
	end if;
	-- could it ever come to this?
	return 1001;
end;
$$ language plpgsql;


-- input: person_id
-- output: invoices.id that's still open aka "cart" - null if none
create or replace function store.cart_get_id(integer, out id integer) as $$
begin
	select v.id into id
	from invoices v
	where person_id = $1
	and payment_date is null;
end;
$$ language plpgsql;


-- input: person_id
-- output: new invoices.id
create or replace function store.cart_new_id(integer, out id integer) as $$
begin
	insert into invoices (person_id, country)
	select p.id, p.country
	from people p
	where p.id = $1
	returning invoices.id into id;
end;
$$ language plpgsql;


create or replace function store.lineitem_calc() returns trigger as $$
declare
	invid integer;
	lsum numeric;
begin
	-- if not deleting, update lineitem price
	if (tg_op != 'DELETE') then
		update lineitems l
		set price = l.quantity * i.price
		from items i
		where l.item_id = i.id
		and l.id = new.id;
	end if;
	-- get invoice_id whether adding or deleting
	if (tg_op = 'INSERT' or tg_op = 'UPDATE') then
		invid := new.invoice_id;
	elsif (tg_op = 'DELETE') then
		invid := old.invoice_id;
	end if;
	-- whether insert|update|delete, these should work:
	select sum(price) into lsum
	from lineitems
	where invoice_id = invid;
	update invoices
	set subtotal = lsum,
	shipping = store.invoice_shipcost(invid),
	total = (lsum + store.invoice_shipcost(invid))
	where id = invid;
	return new;
end;
$$ language plpgsql;
drop trigger if exists lineitem_calc on lineitems cascade;
create trigger lineitem_calc after insert or delete or update of item_id, quantity on lineitems
for each row execute procedure store.lineitem_calc();


create or replace function store.no_alter_paid_lineitem() returns trigger as $$
declare
	paid_invoice integer;
begin
	select v.id into paid_invoice
	from invoices v
	where v.id = old.invoice_id
	and v.payment_date is not null;
	if found then
		raise 'no_alter_paid_lineitem';
	end if;
	if (tg_op = 'DELETE') then
		return old;
	else
		return new;
	end if;
end;
$$ language plpgsql;
drop trigger if exists no_alter_paid_lineitem on lineitems cascade;
create trigger no_alter_paid_lineitem before delete or update on lineitems
for each row execute procedure store.no_alter_paid_lineitem();


create or replace function store.no_alter_shipped_invoice() returns trigger as $$
begin
	if old.ship_date is not null 
		then raise 'no_alter_shipped_invoice';
	end if;
	if (tg_op = 'DELETE') then
		return old;
	else
		return new;
	end if;
end;
$$ language plpgsql;
drop trigger if exists no_alter_shipped_invoice on invoices cascade;
create trigger no_alter_shipped_invoice before delete or update on invoices
for each row execute procedure store.no_alter_shipped_invoice();


-- invoices.id, country,
create or replace function store.invoice_update(integer, char(2),
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	update invoices
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
	update invoices
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


-- person_id, item_id, quantity
create or replace function store.lineitem_add(integer, integer, integer,
	out status smallint, out js json) as $$
declare
	cart_id integer;
	line_id integer;
	e6 text; e7 text; e8 text; e9 text;
begin
	select id into cart_id from store.cart_get_id($1);
	if cart_id is null then
		select id into cart_id from store.cart_new_id($1);
	end if;
	select id into line_id
	from lineitems
	where invoice_id = cart_id
	and item_id = $2;
	if line_id is null then
		insert into lineitems (invoice_id, item_id, quantity)
		values (cart_id, $2, $3)
		returning id into line_id;
	else
		update lineitems
		set quantity = quantity + $3
		where id = line_id;
	end if;
	status := 200;
	js := row_to_json(r.*) from lineitems r where id = line_id;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;


create or replace function store.invoices_get(
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select * from store.invoice_view
		order by id
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;


-- person_id
create or replace function store.items_get_for(integer,
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select i.id, i.name from items i
		join lineitems l on i.id = l.item_id
		join invoices v on l.invoice_id = v.id
		where v.person_id = $1
		and v.payment_date is not null
		order by name
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;


create or replace function store.items_get(
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select * from items order by name
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;


-- invoices.id, shipment info
create or replace function store.invoice_shipped(integer, text,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	update invoices
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


create or replace function store.invoice_delete(integer,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	js := row_to_json(r.*) from store.invoice_view r where id = $1;
	status := 200;
	if js is null then
		status := 404;
		js := '{}';
	else
		delete from invoices where id = $1;
	end if;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;


-- person_id
create or replace function store.invoices_get_for(integer,
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select * from store.invoice_view
		where person_id = $1
		order by id
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;


create or replace function store.invoices_unshipped(
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select * from store.invoice_view
		where payment_date is not null
		and ship_date is null
		and address is not null
		order by id
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;


-- person_id
create or replace function store.cart_get(integer,
	out status smallint, out js json) as $$
declare
	cart_id integer;
begin
	select id into cart_id from store.cart_get_id($1);
	if cart_id is null then
		status := 404;
		js := '{}';
	else
		status := 200;
		js := row_to_json(r) from (
			select * from store.invoice_view where id = cart_id
		) r;
	end if;
end;
$$ language plpgsql;


-- lineitems.id, quantity
create or replace function store.lineitem_update(integer, integer,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	perform 1 from lineitems where id = $1;
	if not found then
		status := 404;
		js := '{}';
	elsif $2 > 0 then
		update lineitems
		set quantity = $2
		where id = $1;
		status := 200;
		js := row_to_json(r.*) from lineitems r where id = $1;
	else
		delete from lineitems where id = $1;
		status := 200;
		js := '{}';
	end if;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;


create or replace function store.invoice_get(integer,
	out status smallint, out js json) as $$
begin
	js := row_to_json(r) from (
		select * from store.invoice_view where id = $1
	) r;
	status := 200;
	if js is null then
		js := '{}';
		status := 404;
	end if;
end;
$$ language plpgsql;


-- person_id
create or replace function store.addresses_get(integer,
	out status smallint, out js json) as $$
begin
	js := json_agg(r) from (
		select id, country, address
		from invoices
		where person_id = $1
		and address is not null
		order by id
	) r;
	status := 200;
	if js is null then
		js := '[]';
	end if;
end;
$$ language plpgsql;


create or replace function store.lineitem_delete(integer,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	js := row_to_json(r.*) from lineitems r where id = $1;
	status := 200;
	if js is null then
		status := 404;
		js := '{}';
	else
		delete from lineitems where id = $1;
	end if;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;



-- invoices.id, payment info
create or replace function store.invoice_paid(integer, text,
	out status smallint, out js json) as $$
declare
	e6 text; e7 text; e8 text; e9 text;
begin
	update invoices
	set payment_date = now(), payment_info = $2
	where id = $1
	and payment_date is null;
	select x.status, x.js into status, js
	from store.invoice_get($1) x;
exception
	when others then get stacked diagnostics e6=returned_sqlstate, e7=message_text, e8=pg_exception_detail, e9=pg_exception_context;
	js := json_build_object('code',e6,'message',e7,'detail',e8,'context',e9);
	status := 500;
end;
$$ language plpgsql;


COMMIT;


