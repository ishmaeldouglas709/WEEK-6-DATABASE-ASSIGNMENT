-- Step 3a: Simulate a disaster.
-- Record the returned timestamp BEFORE running the DELETE — this is the
-- recovery_target_time used in sql/04_recovery_verification.sql / the
-- recovery procedure in scripts/03_disaster_recovery.sh.

SELECT now();            -- e.g. 2025-06-01 10:00:00 -- record this value

DELETE FROM students;    -- oops, simulated disaster
