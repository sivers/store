SCHEMA = 'store'
require_relative 'tester.rb'

class StoreAPITest < Tester

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
    qa('items_get')
    assert_equal @r, [
      {id:2, name:'Everlasting Gobstopper', price:149.99, weight:0.25},
      {id:3, name:'Fizzy Lifting Drink', price:5, weight:1},
      {id:4, name:'JPG of Mr. Wonka', price:2, weight:nil},
      {id:1, name:'Smell the Factory', price:21.23, weight:nil}
    ]
  end

  def test_items_get_for
    qa('items_get_for', 3)
    assert_equal @r, [{id:2, name:'Everlasting Gobstopper'}]
    qa('items_get_for', 4)
    assert_equal @r, [{id:3, name:'Fizzy Lifting Drink'}]
    qa('items_get_for', 99)
    assert_equal @r, []
  end


  def test_invoices_get
    qa('invoices_get')
    ids = @r.map {|x| x[:id]}
    assert_equal(ids, [1, 2, 3, 4])
    # uses same invoice_view as invoice_get
  end

  def test_invoices_get_for
    qa('invoices_get_for', 4)
    assert_equal 1, @r.size
    assert_equal 'Charlie Buckets', @r[0][:name]
    # uses same invoice_view as invoice_get
    qa('invoices_get_for', 99)
    assert_equal @r, []
  end

  def test_invoice_get
    qa('invoice_get', 1)
    assert_equal(@r, @invoice1)
  end

  def test_invoice_delete
    qa('invoice_delete', 4)
    assert_equal(@r, {
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
    qa('invoice_get', 4)
    assert_equal({error: 'not found'}, @r)
    qa('invoice_delete', 1)
    assert_equal(@r[:error], 'no_alter_shipped_invoice')
  end

  def test_invoice_paid
    qa('invoice_paid', 4, 'info here')
    assert_equal Time.now.strftime('%Y-%m-%d'), @r[:payment_date]
    assert_equal 'info here', @r[:payment_info]
  end

  def test_invoice_update
    qa('invoice_update', 4, 'TW')
    assert_equal 4, @r[:id]
    assert_equal 'TW', @r[:country]
    qa('invoice_update', 4, 'XX')
    assert @r[:error].include?('violates')
    qa('invoice_update', 99, 'TW')
    assert_equal({}, @r)
    qa('invoice_update', 4, 'CA', 'street address here')
    assert_equal 'CA', @r[:country]
    assert_equal 'street address here', @r[:address]
    qa('invoice_update', 1, 'XX')
    assert @r[:error].include?('shipped')
  end

  def test_lineitem_delete
    qa('lineitem_delete', 4)
    assert_equal(@r, {id:4, invoice_id:4, item_id:4, quantity:1, price:2})
    qa('invoice_get', 4)
    assert_nil @r[:lineitems]
    qa('lineitem_delete', 4)
    assert_equal(@r, {})
    qa('lineitem_delete', 1)
    assert_equal(@r[:error], 'no_alter_paid_lineitem')
    qa('lineitem_delete', 3)
    assert_equal(@r[:error], 'no_alter_paid_lineitem')
  end

  def test_lineitem_add
    qa('lineitem_add', 7, 3, 10)
    assert @r[:id] > 4
    assert_equal 4, @r[:invoice_id]
    assert_equal 3, @r[:item_id]
    assert_equal 10, @r[:quantity]
    assert_equal 50, @r[:price]  # trigger
  end

  def test_lineitem_add_new
    qa('lineitem_add', 1, 3, 3)
    assert @r[:id] > 4
    assert @r[:invoice_id] > 4
    qa('cart_get', 1)
    assert @r[:id] > 4
    assert_equal 1, @r[:person_id]
    assert_equal Time.now.to_s[0,10], @r[:order_date]
    assert_equal 'SG', @r[:country]
  end

  def test_lineitem_add_update
    qa('lineitem_add', 7, 4, 1)
    assert_equal 2, @r[:quantity]
    qa('lineitem_add', 7, 4, 1)
    assert_equal 3, @r[:quantity]
    qa('lineitem_add', 7, 4, 5)
    assert_equal 8, @r[:quantity]
  end

  def test_lineitem_update
    qa('lineitem_update', 4, 5)
    assert_equal(@r, {id:4, invoice_id:4, item_id:4, quantity:5, price:10})
    qa('lineitem_update', 4, 0)
    assert_equal(@r, {})
    qa('invoice_get', 4)
    assert_nil @r[:lineitems]
  end

  def test_cart_get
    qa('cart_get', 1)
    assert_equal(@r, {error: 'not found'})
    qa('cart_get', 6)
    assert_equal(@r, {error: 'not found'})
    qa('cart_get', 7)
    assert_equal(@r[:person_id], 7)
    assert_equal(@r[:id], 4)
    assert_equal(@r[:lineitems].size, 1)
  end

  def test_addresses_get
    qa('addresses_get', 1)
    assert_equal(@r, [])
    qa('addresses_get', 6)
    assert_equal(@r, [])
    qa('addresses_get', 3)
    assert_equal(@r, [{id:2, country:'GB', address:"Veruca Salt\n10 Posh Lane\nPoshest House\nKensington, London WC1 7NT"}])
  end

  def test_invoices_unshipped
    qa('invoices_unshipped')
    assert_equal 1, @r.size
    assert_equal(@r[0][:address], "Veruca Salt\n10 Posh Lane\nPoshest House\nKensington, London WC1 7NT")
  end

  def test_invoice_shipped
    qa('invoice_shipped', 2, 'Airmail')
    assert_equal('Airmail', @r[:ship_info])
    assert_equal(Time.now.to_s[0,10], @r[:ship_date])
  end
end

