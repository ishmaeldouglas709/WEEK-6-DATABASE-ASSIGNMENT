-- Step 1: Logical backup + restore verification
-- Run against BOTH databases after the pg_restore in scripts/01_backup_and_verify.sh
-- and compare the two counts to confirm the restore matches the source.

-- Run on the restored copy:
SELECT count(*) FROM students;  -- bootcamp_check

-- Run on the original:
SELECT count(*) FROM students;  -- bootcamp
