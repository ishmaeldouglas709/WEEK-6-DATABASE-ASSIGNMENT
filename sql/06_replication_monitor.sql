-- Step 5: Run on the PRIMARY once the standby is started.
-- A row with state = 'streaming' and small/zero lag_bytes confirms the
-- standby is connected and caught up. No rows at all means the standby
-- never connected -- check pg_hba.conf, the password, and that the
-- standby's primary_conninfo points at the right host/port.

SELECT application_name,
       state,
       pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;
