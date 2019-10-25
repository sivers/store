require 'pg'
require 'json'
# USAGE: See and run getdb-example.rb 

# ONLY USE THIS: Curry calldb with a DB connection & schema
def getdb(schema, server='live')
	dbname = ('test' == server) ? 'dude_test' : 'dude'
	unless Object.const_defined?(:DB)
		Object.const_set(:DB, PG::Connection.new(dbname: dbname, user: 'dude'))
	end
	Proc.new do |func, *params|
		okres(calldb(DB, schema, func, params))
	end
end

# INPUT: result of pg.exec_params
# OUTPUT: [boolean, hash] where hash is JSON of response or problem
def okres(res)
	js = JSON.parse(res[0]['js'], symbolize_names: true)
	ok = (res[0]['status'] == '200')
	[ok, js]
end

# return params string for PostgreSQL exec_params
# INPUT: [list, of, things]
# OUTPUT "($1,$2,$3)"
def paramstring(params)
	'(%s)' % (1..params.size).map {|i| "$#{i}"}.join(',')
end

# The real functional function we're going to curry, below
# INPUT: PostgreSQL connection, schema string, function string, params array
def calldb(pg, schema, func, params)
	pg.exec_params('SELECT status, js FROM %s.%s%s' %
		[schema, func, paramstring(params)], params)
end

