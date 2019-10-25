P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class StoreAPITest < Minitest::Test
	include JDB

	def setup
		@invoice1 = {
			id:1,
			person_id:4,
			name:'Charlie Buckets',
			order_date:'2019-10-02',
			payment_date:'2019-10-02',
			payment_info:'PayPal #abc123',
			subtotal:15,
			shipping:6,
			total:21,
			country:'US',
			address:"Charlie Buckets\n3 Skid Row\nHershey, PA 04141",
			ship_date:'2019-10-03',
			ship_info:'usps# a1b2',
			lineitems:[{
				id:1,
				item_id:3,
				name:'Fizzy Lifting Drink',
				quantity:3,
				price:15
			}]
		}
		super
	end

	def test_items_get
		qry('store.items_get()')
		assert_equal @j, [
			{id:2, name:'Everlasting Gobstopper', price:149.99, weight:0.25},
			{id:3, name:'Fizzy Lifting Drink', price:5, weight:1},
			{id:4, name:'JPG of Mr. Wonka', price:2, weight:nil},
			{id:1, name:'Smell the Factory', price:21.23, weight:nil}
		]
	end

	def test_items_get_for
		qry('store.items_get_for(3)')
		assert_equal @j, [{id:2, name:'Everlasting Gobstopper'}]
		qry('store.items_get_for(4)')
		assert_equal @j, [{id:3, name:'Fizzy Lifting Drink'}]
		qry('store.items_get_for(99)')
		assert_equal @j, []
	end

	def test_invoices_get
		qry('store.invoices_get()')
		ids = @j.map {|x| x[:id]}
		assert_equal(ids, [1, 2, 3, 4])
		# uses same invoice_view as invoice_get
	end

	def test_invoices_get_for
		qry('store.invoices_get_for(4)')
		assert_equal 1, @j.size
		assert_equal 'Charlie Buckets', @j[0][:name]
		# uses same invoice_view as invoice_get
		qry('store.invoices_get_for(99)')
		assert_equal @j, []
	end

	def test_invoice_get
		qry('store.invoice_get(1)')
		assert_equal(@j, @invoice1)
	end

	def test_invoice_delete
		qry('store.invoice_delete(4)')
		assert_equal(@j, {
			id:4,
			person_id:7,
			name:'巩俐',
			order_date:'2019-10-02',
			payment_date:nil,
			payment_info:nil,
			subtotal:2,
			shipping:0,
			total:2,
			country:'CN',
			address:nil,
			ship_date:nil,
			ship_info:nil,
			lineitems:[{id:4, item_id:4, name:'JPG of Mr. Wonka', quantity:1, price:2}]
		})
		qry('store.invoice_get(4)')
		assert_equal({}, @j)
		qry('store.invoice_delete(1)')
		assert_equal(@j[:message], 'no_alter_shipped_invoice')
	end

	def test_invoice_paid
		qry("store.invoice_paid(4, 'info here')")
		assert_equal Time.now.strftime('%Y-%m-%d'), @j[:payment_date]
		assert_equal 'info here', @j[:payment_info]
	end

	def test_invoice_update
		qry("store.invoice_update(4, 'TW')")
		assert_equal 4, @j[:id]
		assert_equal 'TW', @j[:country]
		qry("store.invoice_update(4, 'XX')")
		assert @j[:message].include?('violates')
		qry("store.invoice_update(99, 'TW')")
		assert_equal({}, @j)
		qry("store.invoice_update(4, 'CA', 'street address here')")
		assert_equal 'CA', @j[:country]
		assert_equal 'street address here', @j[:address]
		qry("store.invoice_update(1, 'XX')")
		assert @j[:message].include?('shipped')
	end

	def test_lineitem_delete
		qry('store.lineitem_delete(4)')
		assert_equal(@j, {id:4, invoice_id:4, item_id:4, quantity:1, price:2})
		qry('store.invoice_get(4)')
		assert_nil @j[:lineitems]
		qry('store.lineitem_delete(4)')
		assert_equal(@j, {})
		qry('store.lineitem_delete(1)')
		assert_equal(@j[:message], 'no_alter_paid_lineitem')
		qry('store.lineitem_delete(3)')
		assert_equal(@j[:message], 'no_alter_paid_lineitem')
	end

	def test_lineitem_add
		qry('store.lineitem_add(7, 3, 10)')
		assert_equal 5, @j[:id]
		assert_equal 4, @j[:invoice_id]
		assert_equal 3, @j[:item_id]
		assert_equal 10, @j[:quantity]
		assert_equal 50, @j[:price]  # trigger
	end

	def test_lineitem_add_new
		qry('store.lineitem_add(1, 3, 3)')
		assert_equal 5, @j[:id]
		assert_equal 5, @j[:invoice_id]
		qry('store.cart_get(1)')
		assert_equal 5, @j[:id]
		assert_equal 1, @j[:person_id]
		assert_equal Time.now.to_s[0,10], @j[:order_date]
		assert_equal 'SG', @j[:country]
	end

	def test_lineitem_add_update
		qry('store.lineitem_add(7, 4, 1)')
		assert_equal 2, @j[:quantity]
		qry('store.lineitem_add(7, 4, 1)')
		assert_equal 3, @j[:quantity]
		qry('store.lineitem_add(7, 4, 5)')
		assert_equal 8, @j[:quantity]
	end

	def test_lineitem_update
		qry('store.lineitem_update(4, 5)')
		assert_equal(@j, {id:4, invoice_id:4, item_id:4, quantity:5, price:10})
		qry('store.lineitem_update(4, 0)')
		assert_equal(@j, {})
		qry('store.invoice_get(4)')
		assert_nil @j[:lineitems]
	end

	def test_cart_get
		qry('store.cart_get(1)')
		assert_equal(@j, {})
		qry('store.cart_get(6)')
		assert_equal(@j, {})
		qry('store.cart_get(7)')
		assert_equal(@j[:person_id], 7)
		assert_equal(@j[:id], 4)
		assert_equal(@j[:lineitems].size, 1)
	end

	def test_addresses_get
		qry('store.addresses_get(1)')
		assert_equal(@j, [])
		qry('store.addresses_get(6)')
		assert_equal(@j, [])
		qry('store.addresses_get(3)')
		assert_equal(@j, [{id:2, country:'GB', address:"Veruca Salt\n10 Posh Lane\nPoshest House\nKensington, London WC1 7NT"}])
	end

	def test_invoices_unshipped
		qry('store.invoices_unshipped()')
		assert_equal 1, @j.size
		assert_equal(@j[0][:address], "Veruca Salt\n10 Posh Lane\nPoshest House\nKensington, London WC1 7NT")
	end

	def test_invoice_shipped
		qry("store.invoice_shipped(2, 'Airmail')")
		assert_equal('Airmail', @j[:ship_info])
		assert_equal(Time.now.to_s[0,10], @j[:ship_date])
	end
end

