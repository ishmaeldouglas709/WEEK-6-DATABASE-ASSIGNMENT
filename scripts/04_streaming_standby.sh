#!/usr/bin/env bash
# Step 4: Set up a streaming standby
# Before this: run sql/05_replication_role.sql on the PRIMARY, and add
# the line from conf/pg_hba.conf.snippet to the primary's pg_hba.conf,
# then reload (no restart needed for pg_hba.conf changes):
#   sudo systemctl reload postgresql

# Build the standby (can be the same host on a different port for a lab,
# or a separate machine in a real deployment)
pg_basebackup -h 127.0.0.1 -U replicator -D ~/standby -R -P

# NOTE: -R automatically writes postgresql.auto.conf with primary_conninfo
# AND creates a standby.signal file -- the correct mechanism for PG12+,
# no manual edits needed for that part. If running the standby on the
# SAME machine as the primary, also change its port in postgresql.conf
# (e.g. port = 5433) before starting it, or it will conflict.

# Start the standby (adjust the data-directory flag/service name to
# however you're running this second instance):
#   pg_ctl -D ~/standby start

# Then verify with sql/06_replication_monitor.sql on the PRIMARY.
