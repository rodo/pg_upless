--
-- Create the triggers on all table in a schema
--
CREATE OR REPLACE FUNCTION pg_upless_start(
       schema_source NAME)
RETURNS
  text
LANGUAGE plpgsql AS
$$
DECLARE
    qry TEXT;
    ltables RECORD;
BEGIN
    FOR ltables IN
        SELECT table_name FROM information_schema.tables WHERE table_schema = schema_source AND table_type = 'BASE TABLE' AND table_name != 'pg_upless_stats'
    LOOP
        PERFORM pg_upless_start(schema_source, ltables.table_name);
    END LOOP;
    RETURN schema_source ;
END;
$$;


--
-- Create the triggers on a single table
--
CREATE OR REPLACE FUNCTION pg_upless_start(
       schema_source NAME,
       table_source NAME)
RETURNS
  text
LANGUAGE plpgsql AS
$$
DECLARE qry text;
BEGIN

    INSERT INTO @extschema@.pg_upless_start_time(relnamespace, relname)
    VALUES (schema_source, table_source)
    ON CONFLICT (relnamespace, relname) DO NOTHING;

    SELECT pg_upless_create_trigger(schema_source, table_source) INTO qry;
    EXECUTE qry;

    RETURN schema_source || '.' || table_source || '_log';
END;
$$;

CREATE OR REPLACE FUNCTION pg_upless_stats_trg()
RETURNS trigger
LANGUAGE plpgsql AS
$$

BEGIN
   IF NEW != OLD THEN
       INSERT INTO @extschema@.pg_upless_stats (relnamespace, relname, useful, useless)
       VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 1, 0)
       ON CONFLICT (relnamespace, relname) DO UPDATE
       SET useful = pg_upless_stats.useful + 1;
   ELSE
       INSERT INTO @extschema@.pg_upless_stats (relnamespace, relname, useful, useless)
       VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 1, 0)
       ON CONFLICT (relnamespace, relname) DO UPDATE
       SET useless = pg_upless_stats.useless + 1;
    END IF;

    RETURN NEW;
END;
$$;


CREATE OR REPLACE FUNCTION pg_upless_create_trigger(
       schema_source NAME,
       table_source NAME)
RETURNS
  text
LANGUAGE plpgsql AS
$$

BEGIN
   RETURN format('
   CREATE TRIGGER pg_upless_%s_trg
     BEFORE UPDATE ON %s.%s
     FOR EACH ROW
     EXECUTE PROCEDURE pg_upless_stats_trg();
   ', table_source, schema_source, table_source);

END;
$$;
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
