require_relative 'tester.rb'

class StoreTest < Tester

  def test_unique_inv_item
    err = assert_raises PG::UniqueViolation do
      DB.exec("insert into lineitems(invoice_id, item_id) values(4, 4)")
    end
  end

#########################################
########################## TEST TRIGGERS:
#########################################

  def test_lineitem_calc_price
    DB.exec("update lineitems set quantity = 10 where id = 4")
    res = DB.exec("select price from lineitems where id = 4")
    assert_equal 20, res[0]['price'].to_i
    DB.exec("update lineitems set quantity = 50 where id = 4")
    res = DB.exec("select price from lineitems where id = 4")
    assert_equal 100, res[0]['price'].to_i
    DB.exec("update lineitems set quantity = 1, item_id = 2 where id = 4")
    res = DB.exec("select price from lineitems where id = 4")
    assert_equal 149.99, res[0]['price'].to_f
    DB.exec("update lineitems set quantity = 2 where id = 4")
    res = DB.exec("select price from lineitems where id = 4")
    assert_equal 299.98, res[0]['price'].to_f
  end

  def test_lineitem_calc_invoice
    DB.exec("update lineitems set quantity = 10 where id = 4")
    res = DB.exec("select subtotal from invoices where id = 4")
    assert_equal 20, res[0]['subtotal'].to_f
    DB.exec("insert into lineitems values(default, 4, 2, 1, default)")
    res = DB.exec("select subtotal from invoices where id = 4")
    assert_equal 169.99, res[0]['subtotal'].to_f
  end

  def test_lineitem_calc_shipping
    DB.exec("insert into lineitems(invoice_id, item_id, quantity) values (4, 2, 1)")
    res = DB.exec("select shipping, total from invoices where id = 4")
    assert_equal 7, res[0]['shipping'].to_f
    assert_equal 158.99, res[0]['total'].to_f
    DB.exec("insert into lineitems(invoice_id, item_id, quantity) values (4, 3, 1)")
    res = DB.exec("select shipping, total from invoices where id = 4")
    assert_equal 9, res[0]['shipping'].to_f
    assert_equal 165.99, res[0]['total'].to_f
    DB.exec("update lineitems set quantity = 100 where invoice_id = 4 and item_id = 3")
    res = DB.exec("select shipping, total from invoices where id = 4")
    assert_equal 14, res[0]['shipping'].to_f
    assert_equal 665.99, res[0]['total'].to_f
    DB.exec("delete from lineitems where invoice_id = 4 and id > 4")
    res = DB.exec("select shipping, total from invoices where id = 4")
    assert_equal 0, res[0]['shipping'].to_f
    assert_equal 2, res[0]['total'].to_f
    DB.exec("delete from lineitems where invoice_id = 4")
    res = DB.exec("select shipping, total from invoices where id = 4")
    assert_equal 0, res[0]['shipping'].to_f
    assert_equal 0, res[0]['total'].to_f
  end

  def test_no_alter_paid_lineitem1
    err = assert_raises PG::RaiseException do
      DB.exec("delete from lineitems where id = 1")
    end
    assert err.message.include? 'no_alter_paid_lineitem'
  end

  def test_no_alter_paid_lineitem2
    err = assert_raises PG::RaiseException do
      DB.exec("update lineitems set quantity = 9 where id = 1")
    end
    assert err.message.include? 'no_alter_paid_lineitem'
  end

  def test_no_alter_shipped_invoice1
    err = assert_raises PG::RaiseException do
      DB.exec("delete from invoices where id = 1")
    end
    assert err.message.include? 'no_alter_shipped_invoice'
  end

  def test_no_alter_shipped_invoice2
    err = assert_raises PG::RaiseException do
      DB.exec("update invoices set total = 1 where id = 1")
    end
    assert err.message.include? 'no_alter_shipped_invoice'
  end

  def test_ok_alter_unshipped_invoice
    res = DB.exec("update invoices set ship_date=now(), ship_info='FedEx' where id=2 returning *")
    assert_equal Time.now.to_s[0,10], res[0]['ship_date']
    assert_equal 'FedEx', res[0]['ship_info']
  end

#########################################
######################### TEST FUNCTIONS:
#########################################

  def test_invoice_needs_shipment
    res = DB.exec("select * from store.invoice_needs_shipment(1)")
    assert_equal 't', res[0]['invoice_needs_shipment']
    res = DB.exec("select * from store.invoice_needs_shipment(2)")
    assert_equal 't', res[0]['invoice_needs_shipment']
    res = DB.exec("select * from store.invoice_needs_shipment(3)")
    assert_equal 'f', res[0]['invoice_needs_shipment']
    res = DB.exec("select * from store.invoice_needs_shipment(4)")
    assert_equal 'f', res[0]['invoice_needs_shipment']
    res = DB.exec("select * from store.invoice_needs_shipment(99)")
    assert_equal 'f', res[0]['invoice_needs_shipment']
  end

  def test_shipcost
    res = DB.exec("select * from store.shipcost('US', 0)")
    assert_equal '0', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('CA', 0)")
    assert_equal '0', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('ZH', 0)")
    assert_equal '0', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('US', 0.1)")
    assert_equal '3', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('US', 1)")
    assert_equal '4', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('US', 1.5)")
    assert_equal '5', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('US', 4)")
    assert_equal '7', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('US', 4.01)")
    assert_equal '12', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('CA', 0.3)")
    assert_equal '5', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('CA', 1)")
    assert_equal '6', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('CA', 400)")
    assert_equal '13', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('RU', 0.5)")
    assert_equal '7', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('IE', 1)")
    assert_equal '8', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('IE', 1.01)")
    assert_equal '9', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('SG', 400)")
    assert_equal '14', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('XX', 1000)")
    assert_equal '20', res[0]['shipcost']
    res = DB.exec("select * from store.shipcost('XX', -1)")
    assert_equal '20', res[0]['shipcost']
  end

  def test_invoice_shipcost
    res = DB.exec("select * from store.invoice_shipcost(1)")
    assert_equal '6', res[0]['cost']
    res = DB.exec("select * from store.invoice_shipcost(2)")
    assert_equal '10', res[0]['cost']
    res = DB.exec("select * from store.invoice_shipcost(3)")
    assert_equal '0', res[0]['cost']
    res = DB.exec("select * from store.invoice_shipcost(4)")
    assert_equal '0', res[0]['cost']
  end

  def test_cart_get
    res = DB.exec("select * from store.cart_get_id(1)")
    assert_nil res[0]['id']
    res = DB.exec("select * from store.cart_get_id(6)")
    assert_nil res[0]['id']
    res = DB.exec("select * from store.cart_get_id(7)")
    assert_equal '4', res[0]['id']
  end

  def test_cart_new
    res = DB.exec("select * from store.cart_new_id(1)")
    newid = res[0]['id'].to_i
    assert newid > 4
    res = DB.exec("select * from invoices where id = #{newid}")
    assert_equal '1', res[0]['person_id']
    assert_equal 'SG', res[0]['country']
  end
end

