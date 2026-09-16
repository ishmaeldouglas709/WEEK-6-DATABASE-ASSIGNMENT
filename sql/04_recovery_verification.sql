-- Step 3b: Run after recovery completes (scripts/03_disaster_recovery.sh).
-- Row count should reflect the state just BEFORE the DELETE in
-- sql/03_disaster_simulation.sql -- i.e. the delete should be undone.

SELECT count(*) FROM students;

-- If recovery_target_action left the server paused, resume it:
SELECT pg_wal_replay_resume();

-- Once you've confirmed the data is correct, promote out of recovery
-- so the server accepts writes again:
SELECT pg_promote();
