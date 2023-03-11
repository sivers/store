require 'pg'
require 'json'

# USAGE: See and run getdb-example.rb 

# ONLY USE THIS: Curry calldb with a DB connection & schema
def getdb(schema)
  db = PG::Connection.new(dbname: 'sivers', user: 'sivers')
  Proc.new do |func, *params|
    calldb(db, schema, func, params)
  end
end

# The real functional function we're going to curry, below
# INPUT: PostgreSQL connection, schema string, function string, params array
def calldb(pg, schema, func, params)
  # create argument string: "()" or "($1)" or "($1,$2)" etc.
  qs = '(%s)' % (1..params.size).map {|i| "$#{i}"}.join(',')
  # create SQL query combining @schema, function, argument string
  sql = "select ok, js from " + schema + "." + func + qs
  # execute query with its parameters, saving first/only row in r
  r = pg.exec_params(sql, params)[0]
  # return array of: [boolean ok, result in symbol-key hash/array]
  [
    (r['ok'] == 't'),
    JSON.parse(r['js'], symbolize_names: true)
  ]
end

