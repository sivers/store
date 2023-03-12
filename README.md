# PostgreSQL shopping cart

All functionality is in PostgreSQL’s PL/pgSQL functions.

| SELECT * FROM … | result |
|-----------------|--------|
| **items\_get()** | show all items |
| **cart\_get(person\_id)** | get cart (unpaid invoice) |
| **lineitem\_add(person\_id, item\_id, quantity)** | add item to cart |
| **lineitem\_delete(lineitems.id)** | delete lineitem in cart |
| **lineitem\_update(lineitems.id, quantity)** | change quantity (0=delete) |
| **invoice\_get(invoices.id)** | get order |
| **invoice\_update(invoices.id, country)** | update country |
| **invoice\_update(invoices.id, country, address)** | update address |
| **invoice\_delete(invoices.id)** | delete order |
| **invoice\_paid(invoices.id, payment info)** | mark order as paid |
| **invoices\_get()** | show all orders |
| **invoices\_get\_unshipped()** | orders needing to be shipped |
| **invoice\_shipped(invoice\_id, info)** | mark order as shipped |
| **invoices\_get\_for(person\_id)** | this person’s orders |
| **items\_get\_for(person\_id)** | items this person has paid for |

## Install

```
gem install pg
gem install json
sh init.sh
sh reset.sh
ruby test-db.rb
ruby test-api.rb
```

## Every API function returns:

1. “ok” = boolean success/fail
2. “js” = JSON result (if !ok then {error: "explanation"})


## Play around
```
$ irb
irb» require './getdb.rb'
=> true
irb» db = getdb('store')
irb» ok, res = db.call('invoice_get', 4)
irb» res
{:id=>4,
  :person_id=>7,
  :name=>"巩俐",
  :order_date=>"2019-10-02",
  :payment_date=>nil,
  :payment_info=>nil,
  :subtotal=>2,
  :shipping=>0,
  :total=>2,
  :country=>"CN",
  :address=>nil,
  :ship_date=>nil,
  :ship_info=>nil,
  :lineitems=>[{:id=>4, :item_id=>4, :name=>"JPG of Mr. Wonka", :quantity=>1, :price=>2}]}
irb» ok, res = db.call('invoice_paid', 4, 'cash')
irb» puts ok ? 'paid' : res[:error]
paid
irb» ok, res = db.call('invoices_get')
irb» res.map {|i| "%d = %s" % [i[:id], i[:name]]}
=> ["1 = Charlie Buckets", "2 = Veruca Salt", "3 = Augustus Gloop", "4 = 巩俐"]
irb» exit

$ psql -U dude dude
pg» select * from store.invoices_get();
ok │ t
js │ [{"id":1,"person_id":4,"name":"Charlie Buckets","order_date":"2019-10-02","payment_date":"2019-10-02","payment_info":"PayPal #abc123","subtotal":15,"shipping":6,"total":21,"country":"US","address":"Charlie Buckets\n3 Skid Row\nHershey, PA 04141","ship_date":"2019-10-03","ship_info":"usps# a1b2","lineitems":[{"id":1,"item_id":3,"name":"Fizzy Lifting Drink","quantity":3,"price":15}]},
…
pg» select * from store.invoice_shipped(4, 'posted');
ok │ t
js │ {"id":4,"person_id":7,"order_date":"2019-10-02","payment_date":"2023-03-12","payment_info":"cash","subtotal":2,"shipping":0,"total":2,"country":"CN","address":null,"ship_date":"2023-03-12","ship_info":"posted"}
```

## Contents

* **api/** = public API functions (only use these)
* **functions/** = private functions used by API
* **getdb.rb** = helper to call API
* **tables.sql** = tables and indexes
* **test-api.rb** = unit tests of API calls
* **test-db.rb** = unit tests of private functions
* **test\_data.sql** = sample data for testing
* **tester.rb** = helper for unit tests
* **triggers/** = triggers for data logic
* **views/** = re-usable views for JSON


## Schema for functions

All functions, views, and triggers are in the "store" schema.

So any time you make a change, you can run …
"drop schema store cascade; create schema store"
… then re-load them all anytime. It won't lose your data.


## Questions?

Email me at <https://sive.rs/contact>

Sorry I won’t be watching pull-requests or issues here.
I’m posting this just as some example code.

