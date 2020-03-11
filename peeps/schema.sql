begin;
set client_min_messages to error;
set client_encoding = 'UTF8';
drop schema if exists peeps cascade;

create schema peeps;
set search_path = peeps;

-- country codes used mainly for foreign key constraint on people.country
-- from http://en.wikipedia.org/wiki/iso_3166-1_alpha-2 
-- no need for any api to update, insert, or delete from this table.
create table peeps.countries (
	code character(2) not null primary key,
	name text
);

create table peeps.people (
	id serial primary key,
	email text unique check (email ~ '\A\S+@\S+\.\S+\Z'),
	name text not null check (length(name) > 0),
	city text,
	state text,
	country char(2) references peeps.countries(code)
);
commit;
