BEGIN;

-- Define the number of tests to run
SELECT plan(4);

SELECT has_table('public'::name, 'pg_upless_stats'::name);

SELECT has_table('public'::name, 'pg_upless_start_time'::name);

SELECT has_table('public'::name, 'pg_upless_column_exclusion_table'::name);

SELECT has_table('public'::name, 'pg_upless_column_exclusion'::name);


SELECT * FROM finish();
-- Always end unittest with a rollback
ROLLBACK;
