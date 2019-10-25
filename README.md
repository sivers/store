# PostgreSQL shopping cart

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
| **invoices\_get\_for(person\_id)** | this person's orders |
| **items\_get\_for(person\_id)** | items this person has paid for |


