# This file is just some common shared things used by tests in subdirectories
require 'pg'
require 'minitest/autorun'
require 'json'

DB = PG::Connection.new(dbname: 'dude_test', user: 'dude')
SCHEMA ||= File.read('schema.sql')
FIXTURES ||= File.read('fixtures.sql')

class Minitest::Test
	def setup
		DB.exec(P_SCHEMA) if Module::const_defined?('P_SCHEMA')
		DB.exec(SCHEMA)
		DB.exec(P_FIXTURES) if Module::const_defined?('P_FIXTURES')
		DB.exec(FIXTURES)
	end
end

Minitest.after_run do
	DB.exec(P_SCHEMA) if Module::const_defined?('P_SCHEMA')
	DB.exec(SCHEMA)
	DB.exec(P_FIXTURES) if Module::const_defined?('P_FIXTURES')
	DB.exec(FIXTURES)
end

module JDB
	def qry(sql, params=[])
		@res = DB.exec_params("SELECT * FROM #{sql}", params)
		@j = JSON.parse(@res[0]['js'], symbolize_names: true) if(@res[0]['js'])
	end
end

