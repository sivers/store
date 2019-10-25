#!/usr/bin/env ruby
require './getdb.rb'

db = getdb('store', 'test')

ok, res = db.call('invoice_get', 4)
puts res

ok, res = db.call('invoice_paid', 4, 'cash')
if ok
	puts 'paid'
else
	puts 'error'
	puts res.inspect
end

ok, res = db.call('invoices_get')
res.each do |inv|
	puts "%d\t%s" % [inv[:id], inv[:name]]
end


