# pg_upless
PostgreSQL Extension to detect **UP**DATE that are use**less**

pg_upless is a set of functions and tables, to build statistics on useless update statements. With modern ORM it can occurs that sometimes an UPDATE is done without changing any values. If it occurs too often that will impact the performance of your system. **pg_upless** will help to detect them by creating triggers on the tables you want to follow. It's not aimed to be used all the time, it's more a diagnostc tool you activate it a small period of time. Even if it is designed to have the lower imapct as possible it will downgrade by a little your queries performance.

## INSTALL

### install with [pgxn](https://pgxn.org/)

You can install `pg_upless` with PostgreSQL Extension network tool

```
pgxn install pg_upless
```

### install from source code

Clone this repository and buld the extension

```
make install
```

### install on AWS RDS

You can install `pg_upless` on AWS RDS instances b yusing the (pg_tle extension)[https://github.com/aws/pg_tle]. After have created the pg_tle extension you have to load a file `pgtle.pg_upless--X.X.X.sql`, and then you can create the extension as usual.

```sql
CREATE EXTENSION pg_tle;
\i dist/pgtle.pg_upless--0.0.1.sql
CREATE EXTENSION pg_upless;
```

## USAGE

To start collecting data on UPDATES on the table `boats` in schema `public` call the function `pg_upless_start`

```
SELECT pg_upless_start('public','boats');
          pg_upless_start          
-----------------------------------
 Trigger installed on public.boats
```


## Tables

The extension `pg_upless` creates two tables in it's own schema.

* `pg_upless_start_time` stores the start time when the audit began, it will be useful to calculate the rate of the UPDATEs. In case

* `pg_upless_stats` stores the statistics
  
## Functions

### pg_upless_start(schema_name, table_name)

Will start the audit on the table `table_name` in the schema `schema_name`

### pg_upless_start(schema_name)

Will start the audit on all the tables in the schema `schema_name`

### pg_upless_stop(schema_name, table_name)

Will stop the audit on the table `table_name` in the schema `schema_name`. This will remove the trigger created by the function `pg_upless_start`

### pg_upless_stop(schema_name)

Will stop the audit on all the tables in the schema `schema_name`

