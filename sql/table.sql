--
--
--
CREATE TABLE IF NOT EXISTS pg_upless_stats (
  relname      name NOT NULL,
  relnamespace name NOT NULL,
  useful       bigint,
  useless      bigint,
  PRIMARY key (relname, relnamespace)
);
