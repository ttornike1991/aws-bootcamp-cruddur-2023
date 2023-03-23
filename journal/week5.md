# Week 5 — DynamoDB and Serverless Caching

#1 DynamoDB Bash Scripts

```bash

./bin/ddb/schem-load

```

#2 The Boundaries of DynamoDB

- When you write a query you have provide a Primary Key (equality) eg. pk = 'andrew'
- Are you allowed to "update" the Hash and Range?
- No, whenever you change a key (simple or composite) eg. pk or sk you have to create a new item.
- you have to delete the old one
- Key condition expressions for query only for RANGE, HASH is only equality
- Don't create UUID for entity if you don't have an access pattern for it

3 Access Patterns

#3 Pattern A (showing a single conversation)

A user wants to see a list of messages that belong to a message group The messages must be ordered by the created_at timestamp from newest to oldest (DESC)


```sql

SELECT
  messages.uuid,
  messages.display_name,
  messages.message,
  messages.handle,
  messages.created_at -- sk
FROM messages
WHERE
  messages.message_group_uuid = {{message_group_uuid}} -- pk
ORDER BY messages.created_at DESC

```
<span style="color: green;">message_group_uuid comes from Pattern B</span>.
