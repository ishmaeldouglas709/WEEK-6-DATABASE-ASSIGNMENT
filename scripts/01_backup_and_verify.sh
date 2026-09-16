#!/usr/bin/env bash
# Step 1: Logical backup + restore verification
# Pair with: sql/01_restore_verification.sql

mkdir -p ~/backups
pg_dump -Fc -f ~/backups/bootcamp.dump bootcamp
pg_restore --list ~/backups/bootcamp.dump | head

createdb bootcamp_check
pg_restore -d bootcamp_check ~/backups/bootcamp.dump

# Expect: pg_restore --list prints a table-of-contents style listing
# (schemas, tables, indexes, data) with no errors. Then run
# sql/01_restore_verification.sql against both bootcamp_check and
# bootcamp and compare row counts.
