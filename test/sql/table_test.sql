BEGIN;



-- Define the number of tests to run
SELECT plan(2);

SELECT has_table('public'::name, 'pg_upless_stats'::name, 'Table pg_upless_stats exists');

SELECT has_table('public'::name, 'pg_upless_start_time'::name, 'Table pg_upless_start_time exists');

SELECT * FROM finish();
-- Always end unittest with a rollback
ROLLBACK;
