#!/bin/sh
# RESET ALL FUNCTIONS, but leave tables and data untouched.

cmd="psql --quiet -U dude -d dude"
$cmd -c "set plpgsql.extra_warnings to 'all'"

s="store"
$cmd -c "drop schema if exists $s cascade"
$cmd -c "create schema $s"

for f in views/*sql; do $cmd -f $f; done
for f in functions/*sql; do $cmd -f $f; done
for f in triggers/*sql; do $cmd -f $f; done
for f in api/*sql; do $cmd -f $f; done

