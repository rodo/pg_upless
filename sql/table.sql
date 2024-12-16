--
-- The table that will contains the statistics
--
CREATE TABLE IF NOT EXISTS pg_upless_stats (
  relnamespace name NOT NULL,
  relname      name NOT NULL,
  useful       bigint,
  useless      bigint,
  PRIMARY key (relnamespace, relname)
);
--
-- The table that keep the timestamp when we start to collect the data
--
CREATE TABLE IF NOT EXISTS pg_upless_start_time (
  relnamespace name NOT NULL,
  relname      name NOT NULL,
  start_time   timestamp with time zone,
  PRIMARY key (relnamespace, relname)
);
--
-- The table to configure the column to be excluded per table source
--
CREATE TABLE IF NOT EXISTS pg_upless_column_exclusion_table (
  relnamespace name NOT NULL,
  relname      name NOT NULL,
  colname      name NOT NULL,
  defined_at timestamp with time zone DEFAULT current_timestamp,
  defined_by text DEFAULT current_user,
  PRIMARY key (relnamespace, relname, colname)
);
--
-- The table to configure the column to be excluded for all tables
--
CREATE TABLE IF NOT EXISTS pg_upless_column_exclusion (
  colname name NOT NULL PRIMARY KEY,
  defined_at timestamp with time zone DEFAULT current_timestamp,
  defined_by text DEFAULT current_user
);
