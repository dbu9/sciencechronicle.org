---
title: "Select non-duplicates: SQL interview question"
description: "In this blog we examine a seemingly simple problem to filter duplicate rows. A duplicate is defined as a row which has email or phone which is not unique. This OR condition complicates the solution significantly."
date: 2024-09-09T11:52:37.716Z
draft: false
categories: [Computer, SQL]
tags: [sql, commputer interview]
thumbnail: "/article/select-non-duplicates-sql-interview-question/thumb.png"
---

## Task definition

We define the following schema:

```sql
CREATE TABLE dup(id SERIAL PRIMARY KEY, email TEXT NOT NULL, phone NOT NULL);
```

Duplicate rows are defined as two or more rows which have the same `email` OR `phone` columns. 

Our task is to write SQL which selects rows which have no duplicates initially and also any single row which represents a group of duplicates.

## Solution

### Naive solution

The straigtforward and incorrect approach is to apply `DISTINCT` serially. For example:

```sql
INSERT INTO dup(email, phone) VALUES('a','1'),('a','2'), ('b','2'), ('c','1'), ('d', '3')
```

|id|email|phone|
|--|---|---|
|1|a|1|
|2|a|2|
|3|b|2|
|4|c|1|
|5|d|3|

In that table, row 1 is a duplicate of row 4 because of the same phone, row 1 is also a duplicate of row 2 because of the same email, row 3 is a duplicate of row 2 because of the same phone. Thus, the rows 1-4 are are duplicates. The required result of our selection is any row of duplicates group of rows 1-4 and row 5 which has no duplicates.

Let's select:

```sql
SELECT DISTINCT ON(phone) * FROM 
(SELECT DISTINCT ON(email) * FROM dup) AS q;
```

Select on distinct email produces:

|id|email|phone|
|--|---|---|
|1|a|1|
|3|b|2|
|4|c|1|
|5|d|3|

Next select on distinct phone produces:

|id|email|phone|
|--|---|---|
|1|a|1|
|3|b|2|
|5|d|3|

We see that we selected row 1 and 3 although they belong to the same duplicate group.

The change of order of selection does help in that case:

```sql
SELECT DISTINCT ON(email) * FROM 
(SELECT DISTINCT ON(phone) * FROM dup) AS q;
```

Select on distinct phone produces:

|id|email|phone|
|--|---|---|
|1|a|1|
|2|a|2|
|5|d|3|

Next select on distinct email produces:

|id|email|phone|
|--|---|---|
|1|a|1|
|5|d|3|

The correct result was due to a way the duplicates were connected. The following diagram makes this clear. 

![selection illustration](/article/select-non-duplicates-sql-interview-question/groups.png)

We can see that any kind of graph can exist which will fail the naive selection method we use.

### Recursive CTE query

The correct and recursive solution is the following query.

```sql
WITH RECURSIVE connected_groups AS (
	-- Base case: each row starts as its own group
	SELECT 
		id, 
		email, 
		phone, 
		id AS group_id
	FROM dup

	UNION

	-- Recursive case: find connections via email or phone
	SELECT 
		d.id, 
		d.email, 
		d.phone, 
		cg.group_id
	FROM dup d JOIN connected_groups cg 
	ON d.email = cg.email OR d.phone = cg.phone
	WHERE d.id <> cg.id
),
min_group AS (
	-- Find the smallest group_id for each row's group
	SELECT 
		cg.id, 
		MIN(cg.group_id) AS group_id
	FROM connected_groups cg
	GROUP BY 
		cg.id
)
SELECT d.* FROM dup d
JOIN 
  min_group mg 
  ON d.id = mg.id
JOIN (
	-- Select one row per group (e.g., the row with the smallest id)
	SELECT 
		mg.group_id, 
		MIN(mg.id) AS min_id
	FROM min_group mg
	GROUP BY 
		mg.group_id
) grp 
ON mg.group_id = grp.group_id AND mg.id = grp.min_id;
```

Let's examine several cases with that solution.

![cases](/article/select-non-duplicates-sql-interview-question/cases.png)


#### Case 1

|id|email|phone|
|--|--|--|--|
|1|a|1|
|2|a|2|
|3|b|2|
|4|a|3|
|5|a|4|
|6|c|4|

```sql
TRUNCATE dup RESTART IDENTITY;
INSERT INTO dup(email,phone) VALUES
('a','1'),
('a','2'),
('b','2'),
('a','3'),
('a','4'),
('c','4');
```

The result of the query:

```
 id | email | phone 
----+-------+-------
  1 | a     | 1
(1 row)
```

So, it's ok.

#### Case 2

|id|email|phone|
|--|--|--|
|1|a|1|
|2|a|2|
|3|b|2|
|4|c|4|
|5|c|5|
|6|d|5|

```sql
TRUNCATE dup RESTART IDENTITY;
INSERT INTO dup(email,phone) VALUES
('a','1'),
('a','2'),
('b','2'),
('c','4'),
('c','5'),
('d','5');
```

The result of the query:

```
id | email | phone 
----+-------+-------
  4 | c     | 4
  1 | a     | 1
```

This works nice, too.