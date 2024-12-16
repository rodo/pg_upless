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
        PERFORM @extschema@.pg_upless_start(schema_source, ltables.table_name);
    END LOOP;

    RETURN format('Trigger installed on all tables in schema %s', schema_source);
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
    -- keep the time we set it up
    INSERT INTO @extschema@.pg_upless_start_time(relnamespace, relname, start_time)
    VALUES (schema_source, table_source, current_timestamp)
    ON CONFLICT (relnamespace, relname) DO NOTHING;

    -- create the triggers
    SELECT @extschema@.pg_upless_create_trigger(schema_source, table_source) INTO qry;
    EXECUTE qry;

   RETURN format('Trigger installed on %s.%s', schema_source, table_source);
END;
$$;
--
--
--
CREATE OR REPLACE FUNCTION pg_upless_stop(
       schema_source NAME,
       table_source NAME)
RETURNS
  text
LANGUAGE plpgsql AS
$$
DECLARE qry text;
BEGIN

   EXECUTE format('DROP TRIGGER pg_upless_%s_trg ON %s.%s
   ', table_source, schema_source, table_source);

   RETURN format('Trigger dropped on %s.%s', schema_source, table_source);
END;
$$;
--
-- The function called by the trigger
--
-- Will update the stats if the record is changed or not
--
CREATE OR REPLACE FUNCTION pg_upless_stats_trg()
RETURNS trigger
LANGUAGE plpgsql AS
$$

BEGIN
   IF NOT @extschema@.pg_upless_compare_record(NEW, OLD) THEN
       -- records are different
       INSERT INTO @extschema@.pg_upless_stats (relnamespace, relname, useful, useless)
       VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 1, 0)
       ON CONFLICT (relnamespace, relname) DO UPDATE
       SET useful = pg_upless_stats.useful + 1;
   ELSE
       -- records are identical
       INSERT INTO @extschema@.pg_upless_stats (relnamespace, relname, useful, useless)
       VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 1, 0)
       ON CONFLICT (relnamespace, relname) DO UPDATE
       SET useless = pg_upless_stats.useless + 1;
    END IF;

    RETURN NEW;
END;
$$;
--
-- Compare two record
--
-- Return True if the two records are the same
--
CREATE OR REPLACE FUNCTION pg_upless_compare_record(new_r record, old_r record)
RETURNS boolean
LANGUAGE plpgsql AS
$$
DECLARE
  colexclu text[];
BEGIN
   SELECT ARRAY(SELECT colname FROM @extschema@.pg_upless_column_exclusion) INTO colexclu;

   IF to_jsonb(new_r) - colexclu != to_jsonb(old_r) - colexclu THEN
     RETURN False;
   ELSE
     RETURN True;
   END IF;

END;
$$;
--
--
--
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
     EXECUTE PROCEDURE @extschema@.pg_upless_stats_trg();

   ALTER TRIGGER pg_upless_%s_trg ON %s.%s DEPENDS ON EXTENSION pg_upless;
   ', table_source, schema_source, table_source, table_source, schema_source, table_source);
END;
$$;
