BEGIN;



-- Define the number of tests to run
SELECT plan(1);

SELECT has_table('public'::name, 'pg_upless_stats'::name, 'Table pg_upless_stats exists');

SELECT * FROM finish();
-- Always end unittest with a rollback
ROLLBACK;
