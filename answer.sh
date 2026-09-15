#!/usr/bin/env bash
# =========================================================
# Backup, WAL archiving, PITR, and streaming replication lab
# Mixed shell / postgresql.conf / SQL — read the comments,
# don't blindly pipe this whole thing into bash.
# =========================================================

# ---------------------------------------------------------
# Step 1: Logical backup + restore verification
# ---------------------------------------------------------
mkdir -p ~/backups
pg_dump -Fc -f ~/backups/bootcamp.dump bootcamp
pg_restore --list ~/backups/bootcamp.dump | head
createdb bootcamp_check
pg_restore -d bootcamp_check ~/backups/bootcamp.dump

# What to check: pg_restore --list should print a table-of-contents
# style listing (schemas, tables, indexes, data) with no errors.
# Then connect to bootcamp_check and spot-check row counts against
# bootcamp to confirm the restore actually matches:
#   psql -d bootcamp_check -c "SELECT count(*) FROM students;"
#   psql -d bootcamp      -c "SELECT count(*) FROM students;"


# ---------------------------------------------------------
# Step 2: Enable WAL archiving + base backup
# ---------------------------------------------------------

# --- Edit postgresql.conf ---
# IMPORTANT FIX: postgresql.conf is NOT a shell — $USER will NOT
# expand. Hardcode your actual OS username (find it with `whoami`).
#
#   wal_level = replica
#   archive_mode = on
#   archive_command = 'cp %p /home/YOUR_ACTUAL_USERNAME/backups/wal/%f'
#
# (Find your username first:)
whoami

mkdir -p ~/backups/wal
sudo systemctl restart postgresql

# Confirm archiving is actually working before you rely on it:
#   psql -c "SELECT pg_switch_wal();"
#   ls ~/backups/wal/       -- should show a new WAL file appear

pg_basebackup -D ~/backups/base -Ft -z -Xs -P

# NOTE: -Ft -z produces COMPRESSED TAR files:
#   ~/backups/base/base.tar.gz
#   ~/backups/base/pg_wal.tar.gz
# You'll need to extract these during recovery (Step 3) — a tar.gz
# is not a usable data directory on its own.


# ---------------------------------------------------------
# Step 3: Simulate a disaster and recover to a point in time
# ---------------------------------------------------------

# --- In psql, on the live database ---
# SELECT now();            -- record this, e.g. 2025-06-01 10:00:00
# DELETE FROM students;    -- oops

# --- Recovery procedure (run in shell, as the postgres user
#     or with sudo as appropriate for your install) ---

# 1. Stop PostgreSQL
sudo systemctl stop postgresql

# 2. Move the old data directory aside (don't delete outright —
#    keep it until you've confirmed recovery worked) and replace
#    it with the base backup contents.
#    Adjust PGDATA to your actual data directory
#    (find it while the server is running with `SHOW data_directory;`).
PGDATA=/var/lib/postgresql/16/main   # <-- adjust to your version/path
sudo mv "$PGDATA" "${PGDATA}_old_disaster"
sudo mkdir -p "$PGDATA"

# Extract the base backup into the new (empty) data directory
sudo tar -xzf ~/backups/base/base.tar.gz -C "$PGDATA"
sudo mkdir -p "$PGDATA/pg_wal"
sudo tar -xzf ~/backups/base/pg_wal.tar.gz -C "$PGDATA/pg_wal"
sudo chown -R postgres:postgres "$PGDATA"
sudo chmod 700 "$PGDATA"

# 3. Configure recovery in postgresql.conf:
#
#   restore_command = 'cp /home/YOUR_ACTUAL_USERNAME/backups/wal/%f %p'
#   recovery_target_time = '2025-06-01 10:00:00'
#
# FIX: Postgres 12+ no longer uses recovery.conf. You MUST also
# create an empty trigger file in the data directory so Postgres
# knows to enter recovery mode:
sudo -u postgres touch "$PGDATA/recovery.signal"

# 4. Start PostgreSQL
sudo systemctl start postgresql

# Watch the logs during recovery — it should report replaying WAL
# up to (and stopping at) the target time:
sudo journalctl -u postgresql -f
#   or: tail -f /var/log/postgresql/postgresql-*.log

# 5. Verify recovery
#   psql -d bootcamp -c "SELECT count(*) FROM students;"
# Row count should reflect the state just BEFORE the DELETE.

# Once confirmed, promote out of recovery so the server accepts
# writes again:
#   psql -c "SELECT pg_wal_replay_resume();"   -- if paused
#   Or, if recovery_target_action left it paused, use:
#   SELECT pg_promote();


# ---------------------------------------------------------
# Step 4: Set up a streaming standby
# ---------------------------------------------------------

# --- On the primary, in psql ---
# CREATE ROLE replicator
#   WITH REPLICATION LOGIN PASSWORD 'reppass';

# --- In pg_hba.conf on the primary, add: ---
#   host replication replicator 127.0.0.1/32 md5
#
# Then reload (no restart needed for pg_hba.conf changes):
#   sudo systemctl reload postgresql

# --- Build the standby (run where the standby will live —
#     can be the same host on a different port for a lab, or
#     a separate machine in a real deployment) ---
pg_basebackup -h 127.0.0.1 -U replicator -D ~/standby -R -P

# NOTE: the -R flag automatically writes postgresql.auto.conf with
# primary_conninfo AND creates a standby.signal file for you — this
# is the correct/current mechanism for PG12+, no manual edits needed
# for that part. If running the standby on the SAME machine as the
# primary, you must also change its port in postgresql.conf (e.g.
# port = 5433) before starting it, or it will conflict.

# Start the standby (adjust the data-directory flag/service name
# to however you're running this second instance):
#   pg_ctl -D ~/standby start


# ---------------------------------------------------------
# Step 5: Watch replication health (run on the PRIMARY)
# ---------------------------------------------------------
# In psql on the primary:
#
# SELECT application_name, state,
#        pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
# FROM pg_stat_replication;
#
# A row appearing here with state = 'streaming' and a small/zero
# lag_bytes confirms the standby is connected and caught up. No
# rows at all means the standby never connected — check pg_hba.conf,
# the password, and that the standby's primary_conninfo points at
# the right host/port.
