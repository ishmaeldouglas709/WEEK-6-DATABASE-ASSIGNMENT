-- Step 4: Run on the PRIMARY before building the standby.

CREATE ROLE replicator
  WITH REPLICATION LOGIN PASSWORD 'reppass';
