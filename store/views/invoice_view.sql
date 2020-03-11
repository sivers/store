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
	join peeps.people p on v.person_id = p.id;
