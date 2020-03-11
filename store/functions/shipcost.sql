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
	select cost into c from store.shipchart
	where country = $1
	and weight >= $2
	order by cost asc limit 1;
	if c is not null then
		return c;
	end if;
	-- if country didn't match, null means "rest of world"
	select cost into c from store.shipchart
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
