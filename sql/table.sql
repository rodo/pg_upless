--
--
--
CREATE TABLE IF NOT EXISTS pg_upless_stats (
  relnamespace name NOT NULL,
  relname      name NOT NULL,
  useful       bigint,
  useless      bigint,
  PRIMARY key (relnamespace, relname)
);

CREATE TABLE IF NOT EXISTS pg_upless_start_time (
  relnamespace name NOT NULL,
  relname      name NOT NULL,
  start_time   timestamp with time zone,
  PRIMARY key (relnamespace, relname)
);
