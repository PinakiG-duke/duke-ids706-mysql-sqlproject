
# MySQL Quick Reference (Interview-Focused)

## Connect & Context
```sql
-- Select DB
USE retail_demo;
```

## DDL
```sql
CREATE TABLE t (
  id INT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;
```

## DML
```sql
INSERT INTO t (id, name) VALUES (1,'alice');
UPDATE t SET name='bob' WHERE id=1;
-- UPDATE with JOIN
UPDATE products p
JOIN (SELECT product_id, AVG(unit_price) avg_price FROM order_items GROUP BY product_id) a
  ON a.product_id = p.product_id
SET p.unit_price = a.avg_price
WHERE p.category = 'Snacks';
```

## Basics
```sql
SELECT * FROM t WHERE name LIKE 'a%' ORDER BY created_at DESC LIMIT 10;
```

## Aggregates
```sql
SELECT category, COUNT(*) cnt, AVG(price) avg_p FROM prod GROUP BY category HAVING cnt > 5;
```

## JOINs
```sql
SELECT * FROM a JOIN b ON a.id=b.id;
SELECT * FROM a LEFT JOIN b ON a.id=b.id;
SELECT * FROM a RIGHT JOIN b ON a.id=b.id;
-- FULL OUTER emulation
SELECT ... FROM a LEFT JOIN b ON ... WHERE b.id IS NULL
UNION ALL
SELECT ... FROM b RIGHT JOIN a ON ... WHERE a.id IS NULL;
```

## CASE & COALESCE
```sql
SELECT id, CASE WHEN score>=90 THEN 'A' WHEN score>=80 THEN 'B' ELSE 'C' END grade FROM scores;
SELECT COALESCE(nickname, name, 'Unknown') AS display_name FROM users;
```

## Windows
```sql
SELECT x, ROW_NUMBER() OVER (PARTITION BY grp ORDER BY ts) rn FROM t;
SELECT x, LAG(x) OVER (ORDER BY ts) AS prev_x FROM t;
SELECT x, DENSE_RANK() OVER (ORDER BY total DESC) r FROM t;
```

## CTEs
```sql
WITH recent AS (SELECT * FROM t WHERE ts >= CURRENT_DATE - INTERVAL 7 DAY)
SELECT * FROM recent;
-- Recursive
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq WHERE n < 10
)
SELECT * FROM seq;
```

## Dates & Strings
```sql
SELECT DATE_FORMAT(dt, '%Y-%m-%d') as ymd, STR_TO_DATE('2025-10-19','%Y-%m-%d');
SELECT TRIM(BOTH ' ' FROM s), REPLACE(s,'-','_'), UPPER(s), LOWER(s);
```

## JSON
```sql
SELECT JSON_EXTRACT(meta, '$.tags') AS tags FROM products;
SELECT * FROM products WHERE JSON_CONTAINS(JSON_EXTRACT(meta,'$.tags'), JSON_QUOTE('drink'));
```

## Set Ops
```sql
SELECT id FROM a
UNION
SELECT id FROM b;
-- EXCEPT emulation
SELECT a.id
FROM a
WHERE NOT EXISTS (SELECT 1 FROM b WHERE b.id=a.id);
```

## Explain & Index hint (talk track)
- Use `EXPLAIN` to show access paths and key usage.
- Consider composite indexes on (store_id, order_date) for range queries.
