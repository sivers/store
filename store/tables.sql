set client_min_messages to error;
set client_encoding = 'UTF8';
drop schema if exists store cascade;
create schema store;
set search_path = store;

create table store.items (
	id serial primary key,
	name text not null unique,
	price numeric,
	weight numeric
);

create table store.invoices (
	id serial primary key,
	person_id integer not null references peeps.people(id),
	order_date date not null default current_date,
	payment_date date,
	payment_info text,
	subtotal numeric,
	shipping numeric,
	total numeric,
	country char(2) references peeps.countries(code),
	address text,
	ship_date date,
	ship_info text
);
create index on store.invoices(person_id);
create index unshipped on store.invoices(payment_date, ship_date, address);

create table store.lineitems (
	id serial primary key,
	invoice_id integer not null references store.invoices(id) on delete cascade,
	item_id integer not null references store.items(id) on delete restrict,
	quantity smallint not null default 1 check (quantity > 0),
	price numeric,
	unique(invoice_id, item_id)
);
create index on store.lineitems(invoice_id);

create table store.shipchart (
	id serial primary key,
	country char(2) references peeps.countries(code),
	weight numeric not null, -- up to this (invoice.weight <= shipchart.weight)
	cost numeric not null
);
create index on store.shipchart(country, weight);

