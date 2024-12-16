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
        SELECT table_name FROM information_schema.tables WHERE table_schema = schema_source AND table_type = 'BASE TABLE' AND table_name NOT IN ('pg_upless_stats','pg_upless_start_time','pg_upless_column_exclusion')
    LOOP
        PERFORM @extschema@.pg_upless_start(schema_source, ltables.table_name);
    END LOOP;

    RETURN format('Triggers installed on all tables in schema %s', schema_source);
END;
$$;

CREATE OR REPLACE FUNCTION pg_upless_stop(
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
        SELECT table_name FROM information_schema.tables WHERE table_schema = schema_source AND table_type = 'BASE TABLE' AND table_name NOT IN ('pg_upless_stats','pg_upless_start_time','pg_upless_column_exclusion')
    LOOP
        PERFORM @extschema@.pg_upless_stop(schema_source, ltables.table_name);
    END LOOP;

    RETURN format('Triggers removed from all tables in schema %s', schema_source);
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

    INSERT INTO @extschema@.pg_upless_stats (relnamespace, relname, useful, useless)
    VALUES (schema_source, table_source, 0, 0)
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
   IF NOT @extschema@.pg_upless_compare_record(NEW, OLD, TG_TABLE_SCHEMA, TG_TABLE_NAME) THEN
       -- records are different
       UPDATE @extschema@.pg_upless_stats
       SET useful = useful + 1
       WHERE relnamespace = TG_TABLE_SCHEMA AND relname = TG_TABLE_NAME;
   ELSE
       -- records are identical
       UPDATE @extschema@.pg_upless_stats
       SET useless = useless + 1
       WHERE relnamespace = TG_TABLE_SCHEMA AND relname = TG_TABLE_NAME;

    END IF;

    RETURN NEW;
END;
$$;
--
-- Compare two record
--
-- Return True if the two records are the same
--
CREATE OR REPLACE FUNCTION pg_upless_compare_record(
    new_r record,
    old_r record,
    schema_source name,
    table_source name)
RETURNS boolean
LANGUAGE plpgsql AS
$$
DECLARE
  colexclu text[];
BEGIN
   WITH exclu AS (
       SELECT colname FROM @extschema@.pg_upless_column_exclusion
       UNION
       SELECT colname FROM @extschema@.pg_upless_column_exclusion_table
       WHERE relnamespace = schema_source AND relname = table_source
     )
   SELECT ARRAY(SELECT DISTINCT colname FROM exclu) INTO colexclu;

   IF (to_jsonb(new_r) - colexclu) != (to_jsonb(old_r) - colexclu) THEN
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
--
--
--
CREATE OR REPLACE FUNCTION pg_upless_exclude_column(column_name name)
RETURNS text
LANGUAGE plpgsql AS
$$

BEGIN
   INSERT INTO @extschema@.pg_upless_column_exclusion (colname)
       VALUES (column_name)
       ON CONFLICT (colname) DO NOTHING;

   RETURN format ('Column %s is excluded for all tables', column_name);
END;
$$;

CREATE OR REPLACE FUNCTION pg_upless_exclude_column(
    schema_source NAME,
    table_source NAME,
    column_name name)
RETURNS text
LANGUAGE plpgsql AS
$$

BEGIN
   INSERT INTO @extschema@.pg_upless_column_exclusion_table (relnamespace, relname, colname)
       VALUES (schema_source, table_source, column_name)
       ON CONFLICT (relnamespace, relname, colname) DO NOTHING;

   RETURN format ('Column %s is excluded for table %s.%s', column_name, schema_source, table_source);
END;
$$;
