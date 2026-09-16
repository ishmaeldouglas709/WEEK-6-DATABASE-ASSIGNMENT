#!/usr/bin/env bash
# Step 3: Recover to a point in time
# Before this: run sql/03_disaster_simulation.sql and record the timestamp
# it returns, then set that as recovery_target_time in
# conf/postgresql.conf.snippet's [RECOVERY] block below.

# 1. Stop PostgreSQL
sudo systemctl stop postgresql

# 2. Move the old data directory aside (don't delete outright -- keep it
#    until recovery is confirmed) and replace it with the base backup.
#    Find your actual data directory first while the server is running:
#      SHOW data_directory;
PGDATA=/var/lib/postgresql/16/main   # <-- adjust to your version/path
sudo mv "$PGDATA" "${PGDATA}_old_disaster"
sudo mkdir -p "$PGDATA"

# Extract the base backup into the new (empty) data directory
sudo tar -xzf ~/backups/base/base.tar.gz -C "$PGDATA"
sudo mkdir -p "$PGDATA/pg_wal"
sudo tar -xzf ~/backups/base/pg_wal.tar.gz -C "$PGDATA/pg_wal"
sudo chown -R postgres:postgres "$PGDATA"
sudo chmod 700 "$PGDATA"

# 3. Apply the [RECOVERY] settings from conf/postgresql.conf.snippet,
#    then create the trigger file (Postgres 12+ no longer uses
#    recovery.conf -- this signal file is what puts it into recovery mode):
sudo -u postgres touch "$PGDATA/recovery.signal"

# 4. Start PostgreSQL
sudo systemctl start postgresql

# Watch the logs during recovery -- it should report replaying WAL up to
# (and stopping at) the target time:
sudo journalctl -u postgresql -f
#   or: tail -f /var/log/postgresql/postgresql-*.log

# 5. Verify recovery: run sql/04_recovery_verification.sql
