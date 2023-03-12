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


# Provision RDS Instance - Setup Postgres from aws-cli

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

# Setup Scripts for Creat,Connect,Drop,Schema-load,Seed - DATABASE

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

Make file <code>backend-flask/bin/schema-load</code>:

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

Make file <code>backend-flask/bin/seed</code>:

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





