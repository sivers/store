require 'pg'
require 'json'

# constant so it can be called by other scripts like tester.rb
DB = PG::Connection.new(dbname: 'dude', user: 'dude')

# ONLY USE THIS. Curries calldb with a DB connection & schema.
def getdb(schema)
  Proc.new do |func, *params|
    calldb(DB, schema, func, params)
  end
end

# input: PostgreSQL connection, schema string, function name, params array
def calldb(pg, schema, func, params)

  # create argument string: "()" or "($1)" or "($1,$2)" etc.
  qs = '(%s)' % (1..params.size).map {|i| "$#{i}"}.join(',')

  # create SQL query combining schema, function name, argument string
  sql = "select ok, js from " + schema + "." + func + qs

  # execute query with its parameters, saving first/only row in r
  r = pg.exec_params(sql, params)[0]

  # return array of: [boolean ok, result in symbol-key hash or array]
  [
    (r['ok'] == 't'),
    JSON.parse(r['js'], symbolize_names: true)
  ]
end

