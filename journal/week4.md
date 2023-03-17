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

 
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="DB-CREATE"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

 
NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "create database cruddur;"

```


**db-connect script**

Make file <code>backend-flask/bin/db-connect</code>:

```bash
#! /usr/bin/bash


GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="DB-CONNECT"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"



if [ "$1" = "prod" ]; then
    printf "${GREEN}It's PRODUCTION!${NO_COLOR}\n"
    CON_URL=$PROD_CONNECTION_URL
else
    printf "${RED}NOT PRODUCTION!${NO_COLOR}\n"
    CON_URL=$CONNECTION_URL
fi


psql $CON_URL

```


**db-drop script**

Make file <code>backend-flask/bin/db-drop</code>:

```bash
#! /usr/bin/bash

 
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="DB-DROP"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "DROP DATABASE cruddur;"

```


**db-schema-load script**

Make file <code>backend-flask/bin/db-schema-load</code>:

```bash
#!/usr/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
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

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="DB-SEED"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"
echo $seed_path

if [ "$1" = "prod" ]; then
    printf "${GREEN}It's PRODUCTION!${NO_COLOR}\n"
    CON_URL=$PROD_CONNECTION_URL
else
    printf "${RED}NOT PRODUCTION!${NO_COLOR}\n"
    CON_URL=$CONNECTION_URL
fi

psql $CON_URL cruddur < $seed_path


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
    CON_URL=$PROD_CONNECTION_URL
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
#!/usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="RDS-UPDATE-SG-RULE"
printf "${CYAN}== ${LABEL} ==${NO_COLOR}\n"

counter=0
while ! aws ec2 describe-instances &> /dev/null
do
    printf "AWS CLI is not installed yet, waiting for ${counter} seconds...\n"
    sleep 1
    ((counter++))
done

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"

    
```    
We added extra condition to the <code>rds-update-sg-rule</code> to ensure that <code>aws cli</code> is installed(if there is for any reason delay with installation)

**CLI screenshot**

![awssleep](https://user-images.githubusercontent.com/100797221/225666552-7d7fbddc-dd49-4e2e-988a-38572aa01d62.png)





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
Whenever we need to update our security groups we can do this for access. Also we already have <code> bash </code> script for that.

```console

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=GITPOD,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
    
  ```  
  
  # 7 Update Gitpod IP on new env var
  
 ```yml
 
  - name: EXPORT GITPOD IP
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source  "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"

```
 There was issue for <code> npm install </code> in <code>.gitpod.yml</code>, for every new instance it was trying npm install again and again and sometimes it caused an error for <code>node_modules</code>
 
 I modified that task; it will check if there is no module only for that case will be installed:
 
 ```yml
 
 - name: Install NPM dependencies if not already installed
    command: |
      if [ ! -d "$THEIA_WORKSPACE_ROOT/frontend-react-js/node_modules" ]; then
        cd frontend-react-js && npm install
      fi
      
  ```
 
# 8 Lambda function Development

Define environment variable <code>CONNECTION_URL</code> in lamda function console assigne it <code> PROD_CONNECTION_URL</code> variable value.

ADD Layer to Lambda:

AWS Lambda layer for psycopg2

To use in your serverless.yml:
```
functions:
  hello:
    handler: handler.hello
    layers:
      # py 3.6:
      - arn:aws:lambda:us-east-1:898466741470:layer:psycopg2-py36:3
      - arn:aws:lambda:us-east-2:898466741470:layer:psycopg2-py36:1
      - arn:aws:lambda:us-west-2:898466741470:layer:psycopg2-py36:1
      - arn:aws:lambda:eu-central-1:898466741470:layer:psycopg2-py36:2
      - arn:aws:lambda:sa-east-1:898466741470:layer:psycopg2-py36:1
      # py 3.7:
      - arn:aws:lambda:eu-central-1:898466741470:layer:psycopg2-py37:6
      - arn:aws:lambda:ap-southeast-1:898466741470:layer:psycopg2-py37:1
      - arn:aws:lambda:us-east-1:898466741470:layer:psycopg2-py37:3
      - arn:aws:lambda:us-east-2:898466741470:layer:psycopg2-py37:1
      - arn:aws:lambda:us-west-2:898466741470:layer:psycopg2-py37:7
      - arn:aws:lambda:eu-west-1:898466741470:layer:psycopg2-py37:1
      - arn:aws:lambda:eu-west-2:898466741470:layer:psycopg2-py37:1
      - arn:aws:lambda:eu-west-3:898466741470:layer:psycopg2-py37:1
      - arn:aws:lambda:sa-east-1:898466741470:layer:psycopg2-py37:1
      - arn:aws:lambda:ap-southeast-1:898466741470:layer:psycopg2-py37:5
      - arn:aws:lambda:ap-southeast-2:898466741470:layer:psycopg2-py37:1
      - arn:aws:lambda:ca-central-1:898466741470:layer:psycopg2-py37:1
      - arn:aws:lambda:ap-south-1:898466741470:layer:psycopg2-py37:1
      # py 3.8:
      - arn:aws:lambda:ca-central-1:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:us-east-1:898466741470:layer:psycopg2-py38:2
      - arn:aws:lambda:us-east-2:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:us-west-1:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:us-west-2:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:eu-west-1:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:eu-west-2:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:eu-west-3:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:eu-central-1:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:eu-south-1:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:ap-northeast-1:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:ap-southeast-1:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:ap-southeast-2:898466741470:layer:psycopg2-py38:1
      - arn:aws:lambda:sa-east-1:898466741470:layer:psycopg2-py38:1
```      
Regions:
Please use the layer that matches your region, or you will get a permissions error.

If you desire another region, please open an issue.

Make folder<code>aws/lambdas</code>:

In <code> aws/lambdas </code> make file <code> cruddur-post-confirmation.py </code> and insert <code>python</code> script:

```python

import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    user_display_name=user['name']
    user_email=user['email']
    user_handle=user['preferred_username']
    user_cognito_id=user['sub']
     
    try:
        sql = f"""
        INSERT INTO users (display_name, email,handle, cognito_user_id) 
        VALUES('{user_display_name}','{user_email}','{user_handle}','{user_cognito_id}')
        """

        conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
        cur = conn.cursor()
        cur.execute(sql)
        conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        
    finally:
        if conn is not None:
            cur.close()
            conn.close()
            print('Database connection closed.')

    return event
    
 ```
 
 
 We have to edit VPC details  for lambda function configuration
 
 ![vpc](https://user-images.githubusercontent.com/100797221/225717522-5e461bcb-1ff8-40ae-856d-393f123a6d01.png)

Also we have to add <code>Permissions</code> to that function, for that we have to make new <code>AWS Policy</code> and attache it to the <code>AWS Role</code>

```json

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateNetworkInterface",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeInstances",
        "ec2:AttachNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}

```
![policy](https://user-images.githubusercontent.com/100797221/225719251-51124d7f-5058-4869-827b-7705eea7627e.png)




We also updated <code> /backend-flask/db/schema.sql </code>

```sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;

CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
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

**At list delete user from cognito console and resigne up user from application(it must to work)**


# 9 Creating Activities

We make new path <code>backend-flask/db/sql</code>:

In this path we make <code>create.sql</code>, <code>home.sql</code>, <code>object.sql</code>:

<code>create.sql</code> script:

```sql
INSERT INTO public.activities (
  user_uuid,
  message,
  expires_at
)
VALUES (
  (SELECT uuid 
    FROM public.users 
    WHERE users.handle = %(handle)s
    LIMIT 1
  ),
  %(message)s,
  %(expires_at)s
) RETURNING uuid;

```
<code>home.sql</code> script:

```sql

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

```
<code>object.sql</code> script:

```sql

SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.created_at,
  activities.expires_at
FROM public.activities
INNER JOIN public.users ON users.uuid = activities.user_uuid 
WHERE 
  activities.uuid = %(uuid)s

```

We modified also <code>aws/lambdas/cruddur-post-confirmation.py</code>:

```python

import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    user_display_name = user['name']
    user_email = user['email']
    user_handle = user['preferred_username']
    user_cognito_id = user['sub']
    
    try:
        sql = """
            INSERT INTO public.users (
                display_name, 
                email,
                handle, 
                cognito_user_id
            ) 
            VALUES (%s, %s, %s, %s)
        """
        
        params = [
            user_display_name,
            user_email,
            user_handle,
            user_cognito_id
        ]
        
        with psycopg2.connect(os.getenv('CONNECTION_URL')) as conn:
            with conn.cursor() as cur:
                cur.execute(sql, params)
            conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
    else:
        print("Data inserted successfully")
    finally:
        print('Database connection closed.')
    
    return event
```

We make <code>backend-flask/lib/db.py</code>:

```python

from psycopg_pool import ConnectionPool
import os
import re
import sys
from flask import current_app as app

class Db:
  def __init__(self):
    self.init_pool()

  def template(self,*args):
    pathing = list((app.root_path,'db','sql',) + args)
    pathing[-1] = pathing[-1] + ".sql"

    template_path = os.path.join(*pathing)

    green = '\033[92m'
    no_color = '\033[0m'
    print("\n")
    print(f'{green} Load SQL Template: {template_path} {no_color}')

    with open(template_path, 'r') as f:
      template_content = f.read()
    return template_content

  def init_pool(self):
    connection_url = os.getenv("CONNECTION_URL")
    self.pool = ConnectionPool(connection_url)
  # we want to commit data such as an insert
  # be sure to check for RETURNING in all uppercases
  def print_params(self,params):
    blue = '\033[94m'
    no_color = '\033[0m'
    print(f'{blue} SQL Params:{no_color}')
    for key, value in params.items():
      print(key, ":", value)

  def print_sql(self,title,sql):
    cyan = '\033[96m'
    no_color = '\033[0m'
    print(f'{cyan} SQL STATEMENT-[{title}]------{no_color}')
    print(sql)
  def query_commit(self,sql,params={}):
    self.print_sql('commit with returning',sql)

    pattern = r"\bRETURNING\b"
    is_returning_id = re.search(pattern, sql)

    try:
      with self.pool.connection() as conn:
        cur =  conn.cursor()
        cur.execute(sql,params)
        if is_returning_id:
          returning_id = cur.fetchone()[0]
        conn.commit() 
        if is_returning_id:
          return returning_id
    except Exception as err:
      self.print_sql_err(err)
  # when we want to return a json object
  def query_array_json(self,sql,params={}):
    self.print_sql('array',sql)

    wrapped_sql = self.query_wrap_array(sql)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        return json[0]
  # When we want to return an array of json objects
  def query_object_json(self,sql,params={}):

    self.print_sql('json',sql)
    self.print_params(params)
    wrapped_sql = self.query_wrap_object(sql)

    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(wrapped_sql,params)
        json = cur.fetchone()
        if json == None:
          "{}"
        else:
          return json[0]
  def query_wrap_object(self,template):
    sql = f"""
    (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
    {template}
    ) object_row);
    """
    return sql
  def query_wrap_array(self,template):
    sql = f"""
    (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
    {template}
    ) array_row);
    """
    return sql
  def print_sql_err(self,err):
    # get details about the exception
    err_type, err_obj, traceback = sys.exc_info()

    # get the line number when exception occured
    line_num = traceback.tb_lineno

    # print the connect() error
    print ("\npsycopg ERROR:", err, "on line number:", line_num)
    print ("psycopg traceback:", traceback, "-- type:", err_type)

    # print the pgcode and pgerror exceptions
    print ("pgerror:", err.pgerror)
    print ("pgcode:", err.pgcode, "\n")

db = Db()


```

We also modified <code>backend-flask/services/create_activity.py</code>:

```python
from datetime import datetime, timedelta, timezone
import uuid
from lib.db import db

class CreateActivity:
  def run(message, user_handle, ttl):
    model = {
      'errors': None,
      'data': None
    }

    now = datetime.now(timezone.utc).astimezone()

    if (ttl == '30-days'):
      ttl_offset = timedelta(days=30) 
    elif (ttl == '7-days'):
      ttl_offset = timedelta(days=7) 
    elif (ttl == '3-days'):
      ttl_offset = timedelta(days=3) 
    elif (ttl == '1-day'):
      ttl_offset = timedelta(days=1) 
    elif (ttl == '12-hours'):
      ttl_offset = timedelta(hours=12) 
    elif (ttl == '3-hours'):
      ttl_offset = timedelta(hours=3) 
    elif (ttl == '1-hour'):
      ttl_offset = timedelta(hours=1) 
    else:
      model['errors'] = ['ttl_blank']

    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['user_handle_blank']

    if message == None or len(message) < 1:
      model['errors'] = ['message_blank'] 
    elif len(message) > 280:
      model['errors'] = ['message_exceed_max_chars'] 

    if model['errors']:
      model['data'] = {
        'handle':  user_handle,
        'message': message
      }   
    else:
      expires_at = (now + ttl_offset)
      uuid = CreateActivity.create_activity(user_handle,message,expires_at)

      object_json = CreateActivity.query_object_activity(uuid)
      model['data'] = object_json
    return model

  def create_activity(handle, message, expires_at):
    sql = db.template('activities','create')
    uuid = db.query_commit(sql,{
      'handle': handle,
      'message': message,
      'expires_at': expires_at
    })
    return uuid
  def query_object_activity(uuid):
    sql = db.template('activities','object')
    return db.query_object_json(sql,{
      'uuid': uuid
    })

    ```
Also modified <code>backend-flask/services/home_activities.py</code>:

```python

from datetime import datetime, timedelta, timezone
from opentelemetry import trace

from lib.db import db

#tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    #logger.info("HomeActivities")
    #with tracer.start_as_current_span("home-activites-mock-data"):
    #  span = trace.get_current_span()
    #  now = datetime.now(timezone.utc).astimezone()
    #  span.set_attribute("app.now", now.isoformat())
    sql = db.template('activities','home')
    results = db.query_array_json(sql)
    return results


```

In <code>app.py</code> modified <code>data_activities()</code> function:

```python

@app.route("/api/activities", methods=['POST','OPTIONS'])
@cross_origin()
def data_activities():
  user_handle  = request.json['user_handle']
  message = request.json['message']
  ttl = request.json['ttl']
  model = CreateActivity.run(message, user_handle, ttl)
  if model['errors'] is not None:
    return model['errors'], 422
  else:
    return model['data'], 200
  return

```

In frontent we modified  <code>frontend-react-js/src/components/ActivityForm.js</code> <code>onsubmit</code> function snippet:

```javascript

        body: JSON.stringify({
          user_handle: props.user_handle.handle,
          message: message,
          ttl: ttl
        }),
     
  ```

  Also modified <code>frontend-react-js/src/pages/HomeFeedPage.js</code> script  <code> ActivityForm</code> snippet:

  ```javascript

  <ActivityForm
        user_handle={user}
        popped={popped}
        setPopped={setPopped}
        setActivities={setActivities}
  />

  ```










