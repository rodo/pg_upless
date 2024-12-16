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
    RETURN schema_source ;
END;
$$;

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

    RETURN schema_source || '.' || table_source || '_log';
END;
$$;
--
