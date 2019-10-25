BEGIN;
SET client_min_messages TO ERROR;
SET client_encoding = 'UTF8';
DROP SCHEMA IF EXISTS peeps CASCADE;

CREATE SCHEMA peeps;
SET search_path = peeps;

-- Country codes used mainly for foreign key constraint on people.country
-- From http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2 
-- No need for any API to update, insert, or delete from this table.
CREATE TABLE peeps.countries (
	code character(2) NOT NULL primary key,
	name text
);

CREATE TABLE peeps.people (
	id serial primary key,
	email text UNIQUE CHECK (email ~ '\A\S+@\S+\.\S+\Z'),
	name text NOT NULL CHECK (LENGTH(name) > 0),
	city text,
	state text,
	country char(2) REFERENCES peeps.countries(code)
);

COMMIT;
