P_SCHEMA = File.read('../peeps/schema.sql')
P_FIXTURES = File.read('../peeps/fixtures.sql')
require '../test_tools.rb'

class StoreTest < Minitest::Test
	include JDB

	def test_unique_inv_item
		err = assert_raises PG::UniqueViolation do
			DB.exec("INSERT INTO store.lineitems(invoice_id, item_id) VALUES(4, 4)")
		end
	end

#########################################
########################## TEST TRIGGERS:
#########################################

	def test_lineitem_calc_price
		DB.exec("UPDATE store.lineitems SET quantity = 10 WHERE id = 4")
		res = DB.exec("SELECT price FROM store.lineitems WHERE id = 4")
		assert_equal 20, res[0]['price'].to_i
		DB.exec("UPDATE store.lineitems SET quantity = 50 WHERE id = 4")
		res = DB.exec("SELECT price FROM store.lineitems WHERE id = 4")
		assert_equal 100, res[0]['price'].to_i
		DB.exec("UPDATE store.lineitems SET quantity = 1, item_id = 2 WHERE id = 4")
		res = DB.exec("SELECT price FROM store.lineitems WHERE id = 4")
		assert_equal 149.99, res[0]['price'].to_f
		DB.exec("UPDATE store.lineitems SET quantity = 2 WHERE id = 4")
		res = DB.exec("SELECT price FROM store.lineitems WHERE id = 4")
		assert_equal 299.98, res[0]['price'].to_f
	end

	def test_lineitem_calc_invoice
		DB.exec("UPDATE store.lineitems SET quantity = 10 WHERE id = 4")
		res = DB.exec("SELECT subtotal FROM store.invoices WHERE id = 4")
		assert_equal 20, res[0]['subtotal'].to_f
		DB.exec("INSERT INTO store.lineitems VALUES(DEFAULT, 4, 2, 1, DEFAULT)")
		res = DB.exec("SELECT subtotal FROM store.invoices WHERE id = 4")
		assert_equal 169.99, res[0]['subtotal'].to_f
	end

	def test_lineitem_calc_shipping
		DB.exec("INSERT INTO store.lineitems(invoice_id, item_id, quantity) VALUES (4, 2, 1)")
		res = DB.exec("SELECT shipping, total FROM store.invoices WHERE id = 4")
		assert_equal 7, res[0]['shipping'].to_f
		assert_equal 158.99, res[0]['total'].to_f
		DB.exec("INSERT INTO store.lineitems(invoice_id, item_id, quantity) VALUES (4, 3, 1)")
		res = DB.exec("SELECT shipping, total FROM store.invoices WHERE id = 4")
		assert_equal 9, res[0]['shipping'].to_f
		assert_equal 165.99, res[0]['total'].to_f
		DB.exec("UPDATE store.lineitems SET quantity = 100 WHERE id = 6")
		res = DB.exec("SELECT shipping, total FROM store.invoices WHERE id = 4")
		assert_equal 14, res[0]['shipping'].to_f
		assert_equal 665.99, res[0]['total'].to_f
		DB.exec("DELETE FROM store.lineitems WHERE invoice_id = 4 AND id > 4")
		res = DB.exec("SELECT shipping, total FROM store.invoices WHERE id = 4")
		assert_equal 0, res[0]['shipping'].to_f
		assert_equal 2, res[0]['total'].to_f
		DB.exec("DELETE FROM store.lineitems WHERE invoice_id = 4")
		res = DB.exec("SELECT shipping, total FROM store.invoices WHERE id = 4")
		assert_equal 0, res[0]['shipping'].to_f
		assert_equal 0, res[0]['total'].to_f
	end

	def test_no_alter_paid_lineitem
		err = assert_raises PG::RaiseException do
			DB.exec("DELETE FROM store.lineitems WHERE id = 1")
		end
		err = assert_raises PG::RaiseException do
			DB.exec("UPDATE store.lineitems SET quantity = 9 WHERE id = 1")
		end
	end

	def test_no_alter_shipped_invoice
		err = assert_raises PG::RaiseException do
			DB.exec("DELETE FROM store.invoices WHERE id = 1")
		end
		err = assert_raises PG::RaiseException do
			DB.exec("UPDATE store.invoices SET total = 1 WHERE id = 1")
		end
		res = DB.exec("UPDATE store.invoices SET ship_date=NOW(), ship_info='FedEx' WHERE id=2 RETURNING *")
		assert_equal Time.now.to_s[0,10], res[0]['ship_date']
		assert_equal 'FedEx', res[0]['ship_info']
	end

#########################################
######################### TEST FUNCTIONS:
#########################################

	def test_invoice_needs_shipment
		res = DB.exec("SELECT * FROM store.invoice_needs_shipment(1)")
		assert_equal 't', res[0]['invoice_needs_shipment']
		res = DB.exec("SELECT * FROM store.invoice_needs_shipment(2)")
		assert_equal 't', res[0]['invoice_needs_shipment']
		res = DB.exec("SELECT * FROM store.invoice_needs_shipment(3)")
		assert_equal 'f', res[0]['invoice_needs_shipment']
		res = DB.exec("SELECT * FROM store.invoice_needs_shipment(4)")
		assert_equal 'f', res[0]['invoice_needs_shipment']
		res = DB.exec("SELECT * FROM store.invoice_needs_shipment(99)")
		assert_equal 'f', res[0]['invoice_needs_shipment']
	end

	def test_shipcost
		res = DB.exec("SELECT * FROM store.shipcost('US', 0)")
		assert_equal '0', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('CA', 0)")
		assert_equal '0', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('ZH', 0)")
		assert_equal '0', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('US', 0.1)")
		assert_equal '3', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('US', 1)")
		assert_equal '4', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('US', 1.5)")
		assert_equal '5', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('US', 4)")
		assert_equal '7', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('US', 4.01)")
		assert_equal '12', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('CA', 0.3)")
		assert_equal '5', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('CA', 1)")
		assert_equal '6', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('CA', 400)")
		assert_equal '13', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('RU', 0.5)")
		assert_equal '7', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('IE', 1)")
		assert_equal '8', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('IE', 1.01)")
		assert_equal '9', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('SG', 400)")
		assert_equal '14', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('XX', 1000)")
		assert_equal '1000', res[0]['shipcost']
		res = DB.exec("SELECT * FROM store.shipcost('XX', -1)")
		assert_equal '1000', res[0]['shipcost']
	end

	def test_invoice_shipcost
		res = DB.exec("SELECT * FROM store.invoice_shipcost(1)")
		assert_equal '6', res[0]['cost']
		res = DB.exec("SELECT * FROM store.invoice_shipcost(2)")
		assert_equal '10', res[0]['cost']
		res = DB.exec("SELECT * FROM store.invoice_shipcost(3)")
		assert_equal '0', res[0]['cost']
		res = DB.exec("SELECT * FROM store.invoice_shipcost(4)")
		assert_equal '0', res[0]['cost']
	end

	def test_cart_get
		res = DB.exec("SELECT * FROM store.cart_get_id(1)")
		assert_nil res[0]['id']
		res = DB.exec("SELECT * FROM store.cart_get_id(6)")
		assert_nil res[0]['id']
		res = DB.exec("SELECT * FROM store.cart_get_id(7)")
		assert_equal '4', res[0]['id']
	end

	def test_cart_new
		res = DB.exec("SELECT * FROM store.cart_new_id(1)")
		assert_equal '5', res[0]['id']
		res = DB.exec("SELECT * FROM store.invoices WHERE id = 5")
		assert_equal '5', res[0]['id']
		assert_equal '1', res[0]['person_id']
		assert_equal 'SG', res[0]['country']
	end
end

