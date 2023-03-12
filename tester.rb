require_relative 'getdb.rb'
require 'minitest/autorun'

# Tester class = TESTING HELPER
#
# If everything I'm testing is inside one schema (usually the case)
# I can say SCHEMA = 'schemaname' before subclassing this, then no
# need to prefix function names with schema name.
# 
# Use one of three methods:
# q  = regular query, for @r.each looping
# q1 = function with one row result
# qa = API function to put @s = status and @j = js response
#
# Each will put results into @r to test against.
# 
# EXAMPLE:
#
# SCHEMA = 'store'
# qa('something', 'cat', 'dog')
# ... will send this query:
# "select * from store.something($1, $2)", ['cat', 'dog']
# ... and return results in @r, boolean @ok, json @r

class Tester < Minitest::Test

  def setup
    DB.exec("begin")
  end

  def teardown
    DB.exec("rollback")
  end

  def q(sql, *params)
    @r = DB.exec_params(sql, params)
  end

  def qa(funk, *params)
    db = getdb(SCHEMA)
    @ok, @r = db.call(funk, *params)
  end

  def q1(funk, *params)
    funk = (defined? SCHEMA) ? "#{SCHEMA}.#{funk}" : funk
    qs = '(%s)' % (1..params.size).map {|i| "$#{i}"}.join(',')
    res = DB.exec_params("select * from #{funk}#{qs}", params)
    @r = case res.ntuples
      when 0
        {}
      when 1
        res[0]
      else
        res.to_a
    end
  end
end

