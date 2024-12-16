BEGIN;

-- useful for local tests
DROP EXTENSION IF EXISTS pg_upless CASCADE;
CREATE EXTENSION pg_upless ;

-- Define the number of tests to run
SELECT plan(13);

--
CREATE TABLE foobar_upless (id int, fname text DEFAULT 'alpha') ;

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

--
-- Exclude record updated_at
--

CREATE TABLE foobar_updated_at (id int, updated_at timestamp with time zone) ;

-- initialize the historization
--

--

SELECT lives_ok('SELECT pg_upless_start(''public'', ''foobar_updated_at'')', 'Start ok on table with column to exclude');

--
INSERT INTO foobar_updated_at (id, updated_at) VALUES (generate_series(1,10), now() );

-- exclude the column updated_at for all tables
INSERT INTO pg_upless_column_exclusion (colname) VALUES ('updated_at');

UPDATE foobar_updated_at SET id = 7, updated_at = now() + INTERVAL '1 day';

SELECT results_eq(
       'SELECT relnamespace, relname, useful::integer, useless::integer FROM pg_upless_stats WHERE relname=''foobar_updated_at'' ',
       $$VALUES ('public'::name, 'foobar_updated_at'::name, 9,1)$$,
       'The stats are correctly collected with an excluded column');
--
--
--
CREATE TABLE foobar_single (id int PRIMARY KEY, aname text DEFAULT 'alpha', bname text DEFAULT 'alpha') ;
SELECT lives_ok('SELECT pg_upless_start(''public'', ''foobar_single'')', 'The start is ok');

INSERT INTO foobar_single (id) VALUES (1);
UPDATE foobar_single SET id = 1;

SELECT results_eq(
       'SELECT relnamespace, relname, useful::integer, useless::integer FROM pg_upless_stats WHERE relname=''foobar_single'' ',
       $$VALUES ('public'::name, 'foobar_single'::name, 0, 1)$$,
       'The stats are correctly collected');

-- exclude aname for all tables
SELECT lives_ok('SELECT pg_upless_exclude_column(''aname'')', 'Exclude aname with pg_upless_exclude_column');

UPDATE foobar_single SET aname = 'beta' WHERE id = 1;

SELECT results_eq(
       'SELECT relnamespace, relname, useful::integer, useless::integer FROM pg_upless_stats WHERE relname=''foobar_single'' ',
       $$VALUES ('public'::name, 'foobar_single'::name, 0, 2)$$,
       'The stats are correctly collected');



--
-- Exclude column bname for all tables
--
SELECT lives_ok('SELECT pg_upless_exclude_column(''public'', ''foobar_single'', ''bname'')', 'Exclude bname with pg_upless_exclude_column_table');

UPDATE foobar_single SET bname = 'beta' WHERE id = 1;

SELECT results_eq(
       'SELECT relnamespace, relname, useful::integer, useless::integer FROM pg_upless_stats WHERE relname=''foobar_single'' ',
       $$VALUES ('public'::name, 'foobar_single'::name, 0, 3)$$,
       'The stats are correctly collected');


--
SELECT * FROM finish();
-- Always end unittest with a rollback
ROLLBACK;
