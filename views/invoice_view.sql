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
		select lineitems.id, lineitems.item_id, items.name,
			lineitems.quantity, lineitems.price
		from lineitems
		join items on lineitems.item_id = items.id
		where lineitems.invoice_id = v.id
	) ll)
	from invoices v
	join people p on v.person_id = p.id;

