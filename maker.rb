# require this after creating a constant called TOPS of the function names that should come first

File.open('schema.sql', 'w') {|f| f.puts 'BEGIN;'}

def save(txt)
	File.open('schema.sql', 'a') {|f| f.puts txt; f.puts "\n\n"}
end

def topsort(tops, fns)
	tops.reverse.each do |top|
		found = fns.find {|fn| fn.end_with?("/#{top}.sql")}
		if found
			fns.delete(found)
			fns.unshift(found)
		end
	end
	fns
end

save File.read('tables.sql')

topsort(TOPS, Dir['views/*.sql']).each {|fn| save File.read(fn)}
topsort(TOPS, Dir['functions/*.sql']).each {|fn| save File.read(fn)}
topsort(TOPS, Dir['triggers/*.sql']).each {|fn| save File.read(fn)}
topsort(TOPS, Dir['api/*.sql']).each {|fn| save File.read(fn)}

save 'COMMIT;'
