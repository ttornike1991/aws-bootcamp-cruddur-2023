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





# 3 Bash Scripts for db-creat,db-connect,db-rop,db-schema-load,db-Seed,db-setup,db-session,rds-update-sg-rule

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
    CON_URL=$PROD_CONNECTION_URL
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

**db-setup script**

Make file <code>backend-flask/bin/db-setup</code>:

```bash
#! /usr/bin/bash

 
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="DB-SETUP"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

bin_path="$(realpath .)/bin"
 

 
source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"

```

**db-session script**

Make file <code>backend-flask/bin/db-session</code>:

```bash

#! /usr/bin/bash

 
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="DB-SESSIONS"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"


if [ "$1" = "prod" ]; then
    printf "${GREEN}It's PRODUCTION!${NO_COLOR}\n"
    CON_URL=$CONNECTION_URL
else
    printf "${RED}NOT PRODUCTION!${NO_COLOR}\n"
    CON_URL=$CONNECTION_URL
fi


 
NO_DB_URL=$(sed 's/\/cruddur//g' <<<"$CON_URL")
psql $NO_DB_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"

```

**rds-update-sg-rule**

Make file <code>backend-flask/bin/rds-update-sg-rule</code>:

```bash
#! /usr/bin/bash


CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="RDS-UPDATE-SG-RULE"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
    
```    

# 4 Install Postgres Client

We need to set the env var for our backend-flask application:

```yml

  backend-flask:
    environment:
      CONNECTION_URL: "${CONNECTION_URL}"

```

We'll add the following to our <code>requirments.txt</code>:

```text
psycopg[binary]
psycopg[pool]
```
```console
pip install -r requirements.txt

```

# 5 DB Object and Connection Pool

In path <code>backend-flask/lib</code>  add <code>db.py</code>

In <code>db.py</code>:


```python
from psycopg_pool import ConnectionPool
import os

 
def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql


connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)

```
In our <code>/backend-flask/services/home_activities.py</code> we'll replace our mock endpoint with real api call:

Full updated code in <code>home_activities.py</code>:

```python

from datetime import datetime, timedelta, timezone
from opentelemetry import trace
from lib.db import pool,query_wrap_array
tracer = trace.get_tracer("home.activities.here")
 
class HomeActivities:
  def run(logger,cognito_user_id=None):
    # logger.info('home-activities-cloudwatch')
    # with tracer.start_as_current_span("home-page-mock-data"):
    #   span = trace.get_current_span()
    # now = datetime.now(timezone.utc).astimezone()
    #   span.set_attribute("app.now", now.isoformat())  
    #   span.set_attribute("user.id", "We have not User id defined in flask")
    
    sql=query_wrap_array( """
    SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
    """)
    with pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql)
        # this will return a tuple
        # the first field being the data
        json = cur.fetchone()
       
      return json[0]
      return results

```

# 6 Connect to RDS via Gitpod

In order to connect to the RDS instance we need to provide our Gitpod IP and whitelist for inbound traffic on port 5432.

```console

GITPOD_IP=$(curl ifconfig.me)

```

```bash

export GITPOD_IP=$(curl ifconfig.me)

gp env GITPOD_IP=$(curl ifconfig.me)


```

We'll create an inbound rule for Postgres (5432) and provide the GITPOD ID.

We'll get the security group rule id so we can easily modify it in the future from the terminal here in Gitpod.

```bash

export DB_SG_ID="sg-0b725ebab7e25635e"
gp env DB_SG_ID="sg-0b725ebab7e25635e"
export DB_SG_RULE_ID="sgr-070061bba156cfa88"
gp env DB_SG_RULE_ID="sgr-070061bba156cfa88"

``` 
Whenever we need to update our security groups we can do this for access.

```console

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
    
  ```  




