BEGIN;

-- Define the number of tests to run
SELECT plan(6);

SELECT has_function('public'::name,
                    'pg_upless_start'::name,
                    ARRAY['name']);

SELECT has_function('public'::name,
                    'pg_upless_start'::name,
                    ARRAY['name','name']);

SELECT has_function('public'::name,
                    'pg_upless_stop'::name,
                    ARRAY['name','name']);

SELECT has_function('public'::name,
                    'pg_upless_create_trigger'::name,
                    ARRAY['name','name']);

SELECT has_function('public'::name,
                    'pg_upless_compare_record'::name,
                    ARRAY['record','record','name','name']);

SELECT has_function('public'::name,
                    'pg_upless_stats_trg'::name);


SELECT * FROM finish();
-- Always end unittest with a rollback
ROLLBACK;
