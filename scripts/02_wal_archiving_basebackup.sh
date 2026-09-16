#!/usr/bin/env bash
# Step 2: Enable WAL archiving + base backup
# Config change needed first: see conf/postgresql.conf.snippet
# (postgresql.conf is NOT a shell -- $USER will not expand there;
# hardcode your actual OS username, found below.)

whoami   # use this value in conf/postgresql.conf.snippet's archive_command

mkdir -p ~/backups/wal
sudo systemctl restart postgresql

# Confirm archiving is actually working before relying on it:
# run sql/02_wal_switch_check.sql, then:
ls ~/backups/wal/       # should show a new WAL file appear

pg_basebackup -D ~/backups/base -Ft -z -Xs -P

# NOTE: -Ft -z produces COMPRESSED TAR files:
#   ~/backups/base/base.tar.gz
#   ~/backups/base/pg_wal.tar.gz
# These need to be extracted during recovery (see 03_disaster_recovery.sh)
# -- a tar.gz is not a usable data directory on its own.
