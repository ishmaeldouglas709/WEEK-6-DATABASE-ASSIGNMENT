# Week 6: Backups, Point-in-Time Recovery, and Replication

Logical backup + restore verification, WAL archiving, PITR after a
simulated disaster, and a streaming standby -- against a `bootcamp`
PostgreSQL database.

## File map

Each step pairs a shell script (OS-level commands: `pg_dump`,
`systemctl`, directory moves) with SQL run inside `psql`, and config
snippets applied by hand (`postgresql.conf` / `pg_hba.conf` are not
shell scripts and don't take shell substitutions like `$USER`).

| Step | Shell | SQL | Config |
|---|---|---|---|
| 1. Backup + restore verify | `scripts/01_backup_and_verify.sh` | `sql/01_restore_verification.sql` | -- |
| 2. WAL archiving + base backup | `scripts/02_wal_archiving_basebackup.sh` | `sql/02_wal_switch_check.sql` | `conf/postgresql.conf.snippet` [ARCHIVING] |
| 3. Disaster + PITR | `scripts/03_disaster_recovery.sh` | `sql/03_disaster_simulation.sql`, `sql/04_recovery_verification.sql` | `conf/postgresql.conf.snippet` [RECOVERY] |
| 4. Streaming standby | `scripts/04_streaming_standby.sh` | `sql/05_replication_role.sql` | `conf/pg_hba.conf.snippet` |
| 5. Replication health | -- | `sql/06_replication_monitor.sql` | -- |

## Run order

1. `scripts/01_backup_and_verify.sh`, then `sql/01_restore_verification.sql`
   on both `bootcamp` and `bootcamp_check` -- counts should match.
2. Apply `conf/postgresql.conf.snippet` [ARCHIVING] (swap in your real
   username from `whoami`), then `scripts/02_wal_archiving_basebackup.sh`.
   Confirm archiving with `sql/02_wal_switch_check.sql`.
3. Run `sql/03_disaster_simulation.sql`, record the timestamp it prints,
   put that in `conf/postgresql.conf.snippet` [RECOVERY]
   `recovery_target_time`, then run `scripts/03_disaster_recovery.sh`.
   Verify with `sql/04_recovery_verification.sql` -- row count should
   match the state just before the delete.
4. Run `sql/05_replication_role.sql` on the primary, add
   `conf/pg_hba.conf.snippet` to `pg_hba.conf` and reload, then
   `scripts/04_streaming_standby.sh`.
5. Run `sql/06_replication_monitor.sql` on the primary -- expect a row
   with `state = 'streaming'` and low `lag_bytes`.

## Notes / gotchas hit during this lab

- `postgresql.conf` does not expand `$USER` -- the archive/restore
  commands need a hardcoded absolute path with the real OS username.
- PostgreSQL 12+ uses `recovery.signal` in the data directory to enter
  recovery mode, not `recovery.conf`.
- `pg_basebackup -Ft -z` produces compressed tarballs
  (`base.tar.gz`, `pg_wal.tar.gz`) that must be extracted into the data
  directory during recovery -- they aren't a usable data directory as-is.
- `pg_basebackup -R` on the standby writes `postgresql.auto.conf` with
  `primary_conninfo` and creates `standby.signal` automatically; no
  manual edits needed there. If the standby runs on the same host as
  the primary, its port must be changed before starting it.

## Results

<!-- Fill in with your actual run: row counts before/after restore,
     before/after the disaster + recovery, and the replication lag
     query output. This is the evidence a grader is checking for --
     the scripts above are the *procedure*, this section is the *proof*. -->
