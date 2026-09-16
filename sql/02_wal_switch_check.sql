-- Step 2: Confirm WAL archiving is actually working before relying on it.
-- Run this, then check that a new file appears in ~/backups/wal/

SELECT pg_switch_wal();
