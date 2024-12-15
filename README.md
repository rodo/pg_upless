# pg_upless
PostgreSQL Extension to Detect Useless UPDATE

## INSTALL

## USAGE

## Tables

The extension `pg_upless` creates two tables in it's own schema.

The table `pg_upless_start_time` stores the start time when the audit began, it will be useful to calculate the rate of the UPDATEs. In case


## Functions

### pg_upless_start(schema_name, table_name)

Will start the audit on the table `table_name` in the schema `schema_name`

### pg_upless_start(schema_name)

Will start the audit on all the tables in the schema `schema_name`

### pg_upless_stop(schema_name, table_name)

Will stop the audit on the table `table_name` in the schema `schema_name`. This will remove the trigger created by the function `pg_upless_start`