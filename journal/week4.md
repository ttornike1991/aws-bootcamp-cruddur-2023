# Week 4 — Postgres and RDS

## Command Examples:

To connect to psql via the psql client cli tool remember to use the host flag to specific localhost.

```bash
psql -Upostgres --host localhost
```
**Common PSQL commands:**

```sql
\x on -- expanded display when looking at data
\q -- Quit PSQL
\l -- List all databases
\c database_name -- Connect to a specific database
\dt -- List all tables in the current database
\d table_name -- Describe a specific table
\du -- List all users and their roles
\dn -- List all schemas in the current database
CREATE DATABASE database_name; -- Create a new database
DROP DATABASE database_name; -- Delete a database
CREATE TABLE table_name (column1 datatype1, column2 datatype2, ...); -- Create a new table
DROP TABLE table_name; -- Delete a table
SELECT column1, column2, ... FROM table_name WHERE condition; -- Select data from a table
INSERT INTO table_name (column1, column2, ...) VALUES (value1, value2, ...); -- Insert data into a table
UPDATE table_name SET column1 = value1, column2 = value2, ... WHERE condition; -- Update data in a table
DELETE FROM table_name WHERE condition; -- Delete data from a table
```
**Define Variables in the environment:**

```bash
postgresql://[user[:password]@][netloc][:port][/dbname][?param1=value1&...]    #syntax example to connect postgres

export CONNECTION_URL="postgresql://your_db_username:your_db_password@localhost:5432/cruddur"  # export variable localy
gp env CONNECTION_URL="postgresql://your_db_username:your_db_password@localhost:5432/cruddur"  # export variable into gitpod variables storage

export PROD_CONNECTION_URL="postgresql://your_aws_postgres_username:your_aws_postgres_password@your_db_instance_endpoint:5432/cruddur"   # export variable localy
gp env PROD_CONNECTION_URL="postgresql://your_aws_postgres_username:your_aws_postgres_password@your_db_instance_endpoint:5432/cruddur"   # export variable into gitpod variables storage

```

# 1 Provision RDS Instance - Setup Postgres from aws-cli

```aws-cli
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username root \
  --master-user-password huEE33z2Qvl383 \
  --allocated-storage 20 \
  --availability-zone ca-central-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```

<blockquote> This will take about 10-15 mins </blockquote>

From AWS Console We can temporarily stop an RDS instance for a couple of days for cost saveing, when we aren't using it.


# 2 Create database  tables

Make folder <code>backend-flask/db</code>

**Create table:**

Make file <code>backend-flask/db/schema.sql</code>:

```bash
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
```sql
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;

CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text,
  handle text,
  cognito_user_id text,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
); 
```
**Create seed data:**

Make file <code>backend-flask/db/seed.sql</code>:

```sql
-- this file was manually created
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```





# 3 Setup Scripts for db-creat,db-connect,db-rop,db-schema-load,db-Seed 

Make folder <code>backend-flask/bin/</code>:

**db-creat script**

Make file <code>backend-flask/bin/db-creat</code>:

```bash
#! /usr/bin/bash

  
CYAN='\033[1;36m'  #some color styling
NO_COLOR='\033[0m'  #some color styling
LABEL="DB-CREATE"   
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"   

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "create database cruddur;"

```


**db-connect script**

Make file <code>backend-flask/bin/db-connect</code>:

```bash
#! /usr/bin/bash

CYAN='\033[1;36m'  #some color styling
NO_COLOR='\033[0m'  #some color styling
LABEL="DB-CONNECT"   
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"   

psql $CONNECTION_URL

```


**db-drop script**

Make file <code>backend-flask/bin/db-drop</code>:

```bash
#! /usr/bin/bash

 
CYAN='\033[1;36m'  #some color styling
NO_COLOR='\033[0m' #some color styling
LABEL="DB-DROP"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "DROP DATABASE cruddur;"

```


**db-schema-load script**

Make file <code>backend-flask/bin/db-schema-load</code>:

```bash
#!/usr/bin/bash

GREEN='\033[0;32m'   #some color styling
RED='\033[0;31m'      #some color styling
CYAN='\033[1;36m'      #some color styling
NO_COLOR='\033[0m'       #some color styling
LABEL="DB-SCHEMA-LOADED"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

schema_path="$(realpath .)/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
    printf "${GREEN}It's PRODUCTION!${NO_COLOR}\n"
    CON_URL=$CONNECTION_URL
else
    printf "${RED}NOT PRODUCTION!${NO_COLOR}\n"
    CON_URL=$CONNECTION_URL
fi

psql $CON_URL cruddur < $schema_path

```

**db-seed script**

Make file <code>backend-flask/bin/db-seed</code>:

```bash
#!/usr/bin/bash
  
GREEN='\033[0;32m'   #some color styling
RED='\033[0;31m'     #some color styling
CYAN='\033[1;36m'    #some color styling
NO_COLOR='\033[0m'    #some color styling
LABEL="DB-SCHEMA-LOADED"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

schema_path="$(realpath .)/db/schema.sql"
echo $schema_path

if [ "$1" = "prod" ]; then
    printf "${GREEN}It's PRODUCTION!${NO_COLOR}\n"
    CON_URL=$CONNECTION_URL
else
    printf "${RED}NOT PRODUCTION!${NO_COLOR}\n"
    CON_URL=$CONNECTION_URL
fi

psql $CON_URL cruddur < $schema_path

```





