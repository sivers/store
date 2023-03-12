#!/bin/sh
cmd="psql --quiet -U dude -d dude"
dropdb --if-exists dude
createdb -O dude dude
$cmd -f tables.sql
$cmd -f test_data.sql

#sh reset.sh

