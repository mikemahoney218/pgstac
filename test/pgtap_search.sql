\unset ECHO
\set QUIET 1 -- Turn off echo and keep things quiet.
 -- Format the output for nice TAP.
\pset format unaligned
\pset tuples_only true
\pset pager off
\timing off -- Revert all changes on failure.
\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true -- Load the TAP functions.
BEGIN;


CREATE EXTENSION IF NOT EXISTS pgtap;


SET SEARCH_PATH TO pgstac,
                   pgtap,
                   public;

-- Plan the tests.
--SELECT plan(62);

SELECT *
FROM no_plan();

-- Run the tests.
\i sql/005_search_cql.sql
SELECT has_function('pgstac'::name, 'parse_dtrange', ARRAY['jsonb']);


SELECT results_eq($$ SELECT parse_dtrange('["2020-01-01","2021-01-01"]') $$, $$ SELECT '["2020-01-01 00:00:00+00","2021-01-01 00:00:00+00")'::tstzrange $$, 'daterange passed as array range');


SELECT results_eq($$ SELECT parse_dtrange('"2020-01-01/2021-01-01"') $$, $$ SELECT '["2020-01-01 00:00:00+00","2021-01-01 00:00:00+00")'::tstzrange $$, 'date range passed as string range');


SELECT has_function('pgstac'::name, 'bbox_geom', ARRAY['jsonb']);


SELECT results_eq($$ SELECT bbox_geom('[0,1,2,3]') $$, $$ SELECT 'SRID=4326;POLYGON((0 1,0 3,2 3,2 1,0 1))'::geometry $$, '2d bbox');


SELECT results_eq($$ SELECT bbox_geom('[0,1,2,3,4,5]'::jsonb) $$, $$ SELECT '010F0000A0E610000006000000010300008001000000050000000000000000000000000000000000F03F00000000000000400000000000000000000000000000104000000000000000400000000000000840000000000000104000000000000000400000000000000840000000000000F03F00000000000000400000000000000000000000000000F03F0000000000000040010300008001000000050000000000000000000000000000000000F03F00000000000014400000000000000840000000000000F03F00000000000014400000000000000840000000000000104000000000000014400000000000000000000000000000104000000000000014400000000000000000000000000000F03F0000000000001440010300008001000000050000000000000000000000000000000000F03F00000000000000400000000000000000000000000000F03F00000000000014400000000000000000000000000000104000000000000014400000000000000000000000000000104000000000000000400000000000000000000000000000F03F0000000000000040010300008001000000050000000000000000000840000000000000F03F00000000000000400000000000000840000000000000104000000000000000400000000000000840000000000000104000000000000014400000000000000840000000000000F03F00000000000014400000000000000840000000000000F03F0000000000000040010300008001000000050000000000000000000000000000000000F03F00000000000000400000000000000840000000000000F03F00000000000000400000000000000840000000000000F03F00000000000014400000000000000000000000000000F03F00000000000014400000000000000000000000000000F03F000000000000004001030000800100000005000000000000000000000000000000000010400000000000000040000000000000000000000000000010400000000000001440000000000000084000000000000010400000000000001440000000000000084000000000000010400000000000000040000000000000000000000000000010400000000000000040'::geometry $$, '3d bbox');


SELECT has_function('pgstac'::name, 'add_filters_to_cql', ARRAY['jsonb']);

SELECT results_eq($$
    SELECT add_filters_to_cql('{"id":["a","b"]}'::jsonb);
    $$,$$
    SELECT '{"filter":{"and": [{"in": [{"property": "id"}, ["a", "b"]]}]}}'::jsonb;
    $$,
    'Test that id gets added to cql filter when cql filter does not exist'
);

SELECT results_eq($$
    SELECT add_filters_to_cql('{"id":["a","b"],"filter":{"and":[{"eq":[1,1]}]}}'::jsonb);
    $$,$$
    SELECT '{"filter":{"and": [{"and": [{"eq": [1, 1]}]}, {"and": [{"in": [{"property": "id"}, ["a", "b"]]}]}]}}'::jsonb;
    $$,
    'Test that id gets added to cql filter when cql filter does exist'
);

SELECT has_function('pgstac'::name, 'cql_and_append', ARRAY['jsonb','jsonb']);

SELECT has_function('pgstac'::name, 'query_to_cqlfilter', ARRAY['jsonb']);

SELECT results_eq($$
    SELECT query_to_cqlfilter('{"query":{"a":{"gt":0,"lte":10},"b":"test"}}');
    $$,$$
    SELECT '{"filter":{"and": [{"gt": [{"property": "a"}, 0]}, {"lte": [{"property": "a"}, 10]}, {"eq": [{"property": "b"}, "test"]}]}}'::jsonb;
    $$,
    'Test that query_to_cqlfilter appropriately converts old style query items to cql filters'
);


SELECT has_function('pgstac'::name, 'sort_sqlorderby', ARRAY['jsonb','boolean']);

SELECT results_eq($$
    SELECT sort_sqlorderby('[{"field":"datetime","direction":"desc"},{"field":"eo:cloudcover","direction":"asc"}]'::jsonb);
    $$,$$
    SELECT ' ORDER BY datetime DESC, eo:cloudcover ASC, id DESC ';
    $$,
    'Test creation of sort sql'
);


SELECT results_eq($$
    SELECT sort_sqlorderby('[{"field":"datetime","direction":"desc"},{"field":"eo:cloudcover","direction":"asc"}]'::jsonb, true);
    $$,$$
    SELECT ' ORDER BY datetime ASC, eo:cloudcover DESC, id ASC ';
    $$,
    'Test creation of reverse sort sql'
);

/* template
SELECT results_eq($$

    $$,$$

    $$,
    'Test that ...'
);
*/
-- Finish the tests and clean up.

SELECT *
FROM finish();


ROLLBACK;