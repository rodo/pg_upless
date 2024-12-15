BEGIN;

-- useful for local tests
TRUNCATE pg_upless_start_time;
TRUNCATE pg_upless_stats;

-- Define the number of tests to run
SELECT plan(5);

CREATE TABLE foobar_upless (id int, fname text DEFAULT 'alpha') ;

-- initialize the historization
--

--
PREPARE call_func AS
SELECT pg_upless_start('public', 'foobar_upless');

SELECT lives_ok('call_func', 'The start is ok');

--
INSERT INTO foobar_upless (id) VALUES (generate_series(1,10) );

UPDATE foobar_upless SET id = 7;

SELECT results_eq(
       'SELECT relnamespace, relname, useful::integer, useless::integer FROM pg_upless_stats',
       $$VALUES ('public'::name, 'foobar_upless'::name, 9,1)$$,
       'The stats are correctly collected');

SELECT results_eq(
       'SELECT count(*)::int FROM pg_upless_start_time',
       $$VALUES (1)$$,
       'The stats are correctly collected');


SELECT lives_ok('SELECT pg_upless_stop(''public'', ''foobar_upless'')', 'The stop is ok');

SELECT lives_ok('SELECT pg_upless_start(''public'', ''foobar_upless'')', 'The start after a stop is ok');


SELECT * FROM finish();
-- Always end unittest with a rollback
ROLLBACK;
