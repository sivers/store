#!/usr/bin/env ruby
# When you change any SQL files, run make.rb to output a new schema.sql

File.open('schema.sql', 'w') {|f| f.puts 'BEGIN;'}

def save(txt)
	File.open('schema.sql', 'a') {|f| f.puts txt; f.puts "\n\n"}
end

save File.read('tables.sql')

Dir['views/*.sql'].each {|fn| save File.read(fn)}
Dir['functions/*.sql'].each {|fn| save File.read(fn)}
Dir['triggers/*.sql'].each {|fn| save File.read(fn)}
Dir['api/*.sql'].each {|fn| save File.read(fn)}

save 'COMMIT;'
