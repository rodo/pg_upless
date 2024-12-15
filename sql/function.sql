--
--
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
       INSERT INTO @extschema@.pg_upless_stats (relname, relnamespace, useful, useless)
       VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 1, 0)
       ON CONFLICT (relname, relnamespace) DO UPDATE
       SET useful = pg_upless_stats.useful + 1;
   ELSE
       INSERT INTO @extschema@.pg_upless_stats (relname, relnamespace, useful, useless)
       VALUES (TG_TABLE_SCHEMA, TG_TABLE_NAME, 1, 0)
       ON CONFLICT (relname, relnamespace) DO UPDATE
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
