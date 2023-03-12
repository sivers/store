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
createuser -s dude
createdb -U dude dude
gem install pg
gem install json
cd store
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
irb» db = getdb('store')
irb» ok, res = db.call('invoice_get', 4)
irb» puts res
irb» ok, res = db.call('invoice_paid', 4, 'cash')
irb» puts ok ? 'paid' : res[:error]
irb» ok, res = db.call('invoices_get')
irb» res.each do |inv|
irb»   puts "%d\t%s" % [inv[:id], inv[:name]]
irb» end
irb» exit

$ psql -U dude dude
pg» select * from store.invoices_get();
pg» select * from store.invoice_shipped(4, 'posted');
```

## Contents

* **tables.sql** = tables and indexes
* **api/** = public API functions (only use these)
* **functions/** = private functions used by API
* **triggers/** = triggers for data logic
* **views/** = re-usable views for JSON
* **test-api.rb** = unit tests of API calls
* **test\_data.sql** = sample data I use for testing


## Schema for functions

All functions, views, and triggers are in the "store" schema.

So any time you make a change, you can run …
"drop schema store cascade; create schema store"
… then re-load them all anytime. It won't lose your data.


## Questions?

Email me at <https://sive.rs/contact>

Sorry I won’t be watching pull-requests or issues here.
I’m posting this just as some example code.

