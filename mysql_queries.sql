USE retail_demo;


-- MySQL 8.0+ Query Pack (interview-ready). Assumes USE retail_demo;

-- 1) Basics: SELECT/WHERE/ORDER BY + LIMIT
SELECT customer_id,
       CONCAT(first_name,' ',last_name) AS full_name,
       email, created_at
FROM customers
WHERE created_at BETWEEN '2025-09-01' AND '2025-09-30'
ORDER BY created_at DESC, customer_id DESC
LIMIT 10;

-- 2) Aggregates + GROUP BY + ORDER BY
SELECT p.category,
       SUM(oi.quantity)                       AS total_units,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS gross_revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY gross_revenue DESC;

-- 3) HAVING on aggregate (store revenue threshold)
SELECT s.store_id, s.store_name,
       ROUND(SUM(oi.quantity * oi.unit_price), 2) AS store_revenue
FROM stores s
JOIN orders o  ON o.store_id = s.store_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY s.store_id, s.store_name
HAVING store_revenue > 15
ORDER BY store_revenue DESC;

-- 4) INNER JOIN: paid orders
SELECT o.order_id, o.status, o.order_date, p.amount, p.method
FROM orders o
JOIN payments p ON p.order_id = o.order_id
ORDER BY o.order_date, o.order_id;

-- 5) LEFT JOIN anti-join: orders without payments
SELECT o.order_id, o.status, o.order_date, p.amount
FROM orders o
LEFT JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_id IS NULL
ORDER BY o.order_id;

-- 6) RIGHT JOIN example (MySQL supports RIGHT JOIN)
SELECT o.order_id, o.status, p.amount
FROM payments p
RIGHT JOIN orders o ON o.order_id = p.order_id
WHERE p.payment_id IS NULL
ORDER BY o.order_id;

-- 7) FULL OUTER JOIN emulation (MySQL lacks FULL JOIN)
-- Union of left-only and right-only + inner if desired
SELECT o.order_id, o.status, p.amount, 'LEFT_ONLY' AS side
FROM orders o
LEFT JOIN payments p ON p.order_id = o.order_id
WHERE p.payment_id IS NULL
UNION ALL
SELECT o.order_id, o.status, p.amount, 'RIGHT_ONLY' AS side
FROM payments p
RIGHT JOIN orders o ON o.order_id = p.order_id
WHERE p.payment_id IS NULL;

-- 8) CASE WHEN bucketing
SELECT o.order_id, o.status,
       CASE
         WHEN o.status IN ('PLACED','PAID') THEN 'OPEN'
         WHEN o.status IN ('SHIPPED','DELIVERED') THEN 'CLOSED'
         WHEN o.status = 'CANCELLED' THEN 'VOID'
         ELSE 'UNKNOWN'
       END AS lifecycle_bucket
FROM orders o
ORDER BY o.order_id;

-- 9) Window functions — ROW_NUMBER + per-order revenue
WITH order_totals AS (
  SELECT o.order_id, o.customer_id, o.order_date,
         SUM(oi.quantity * oi.unit_price) AS order_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.order_id, o.customer_id, o.order_date
)
SELECT c.customer_id,
       CONCAT(c.first_name,' ',c.last_name) AS customer,
       o.order_id, o.order_date, o.order_revenue,
       ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date DESC, o.order_id DESC) AS rn
FROM order_totals o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY c.customer_id, rn;

-- 10) Window functions — DENSE_RANK by store revenue
SELECT s.store_id, s.store_name,
       ROUND(SUM(oi.quantity * oi.unit_price),2) AS store_revenue,
       DENSE_RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank
FROM stores s
JOIN orders o  ON o.store_id = s.store_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY s.store_id, s.store_name
ORDER BY revenue_rank, s.store_id;

-- 11) Window functions — LAG/LEAD price tracking (SKU)
WITH sku_prices AS (
  SELECT oi.order_id, oi.product_id, p.sku, oi.unit_price, o.order_date
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
  JOIN orders o   ON o.order_id = oi.order_id
  WHERE p.sku = 'SKU-TBR-002'
)
SELECT order_id, sku, unit_price, order_date,
       LAG(unit_price)  OVER (ORDER BY order_date, order_id) AS prior_price,
       LEAD(unit_price) OVER (ORDER BY order_date, order_id) AS next_price,
       CASE
         WHEN LAG(unit_price)  OVER (ORDER BY order_date, order_id) IS NULL THEN 'FIRST'
         WHEN unit_price > LAG(unit_price) OVER (ORDER BY order_date, order_id) THEN 'UP'
         WHEN unit_price < LAG(unit_price) OVER (ORDER BY order_date, order_id) THEN 'DOWN'
         ELSE 'SAME'
       END AS price_trend
FROM sku_prices
ORDER BY order_date, order_id;

-- 12) CTE (recursive) — Daily revenue calendar (FIXED for MySQL)
WITH RECURSIVE calendar AS (
  SELECT DATE('2025-09-20') AS d
  UNION ALL
  SELECT DATE_ADD(d, INTERVAL 1 DAY) FROM calendar WHERE d < DATE('2025-10-05')
),
order_totals AS (
  SELECT o.order_date AS d,
         ROUND(SUM(oi.quantity * oi.unit_price),2) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.order_date
)
SELECT c.d AS date,
       COALESCE(ot.revenue, 0) AS revenue
FROM calendar c
LEFT JOIN order_totals ot ON ot.d = c.d
ORDER BY c.d;

-- 13) Set operations — UNION and anti-join (EXCEPT emulation)
-- MySQL does not support EXCEPT; emulate with NOT EXISTS.
-- Customers at store 1 OR 2 (UNION)
WITH s1 AS (SELECT DISTINCT customer_id FROM orders WHERE store_id = 1),
     s2 AS (SELECT DISTINCT customer_id FROM orders WHERE store_id = 2)
SELECT 'UNION' AS op, customer_id FROM s1
UNION
SELECT 'UNION', customer_id FROM s2
ORDER BY customer_id;

-- s1 EXCEPT s2 (anti-join)
SELECT 'EXCEPT' AS op, s1.customer_id
FROM s1
WHERE NOT EXISTS (SELECT 1 FROM s2 WHERE s2.customer_id = s1.customer_id)
ORDER BY s1.customer_id;

-- 14) String cleaning — normalize email domains, simple validation
SELECT customer_id, email,
       CASE
         WHEN INSTR(email,'@') > 0
              THEN CONCAT(SUBSTRING(email,1,INSTR(email,'@')),
                          UPPER(SUBSTRING(email, INSTR(email,'@')+1)))
         ELSE email
       END AS normalized_email,
       CASE WHEN INSTR(email,'@') = 0 THEN 1 ELSE 0 END AS is_suspicious
FROM customers
ORDER BY customer_id;

-- 15) Date functions — month & weekday formatting, rolling 7-day revenue
-- (FORMAT with DATE_FORMAT; rolling sum as window with RANGE)
WITH daily_rev AS (
  SELECT o.order_date AS d,
         SUM(oi.quantity * oi.unit_price) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.order_date
)
SELECT d,
       DATE_FORMAT(d, '%Y-%m') AS yyyy_mm,
       DATE_FORMAT(d, '%a')    AS weekday,
       SUM(revenue) OVER (
         ORDER BY d
         RANGE BETWEEN INTERVAL 6 DAY PRECEDING AND CURRENT ROW
       ) AS revenue_7d
FROM daily_rev
ORDER BY d;

-- 16) JSON feature (extra): find products tagged 'drink'
SELECT product_id, sku, product_name
FROM products
WHERE JSON_CONTAINS(JSON_EXTRACT(meta, '$.tags'), JSON_QUOTE('drink'));

-- 17) RIGHT JOIN + WHERE/HAVING nuance: latest order per customer
WITH ranked AS (
  SELECT o.order_id, o.customer_id, o.order_date,
         ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC, o.order_id DESC) AS rn
  FROM orders o
)
SELECT c.customer_id, CONCAT(c.first_name,' ',c.last_name) AS customer, r.order_id, r.order_date
FROM customers c
RIGHT JOIN ranked r ON r.customer_id = c.customer_id
WHERE r.rn = 1
ORDER BY c.customer_id;

-- 18) UPDATE with JOIN (classic MySQL interview pattern)
UPDATE products p
JOIN (
  SELECT product_id, AVG(unit_price) AS avg_unit_price
  FROM order_items
  GROUP BY product_id
) t ON t.product_id = p.product_id
SET p.unit_price = t.avg_unit_price
WHERE p.category = 'Snacks';

-- 19) CREATE TABLE AS (CTAS) for a reporting table
DROP TABLE IF EXISTS daily_revenue_report;
CREATE TABLE daily_revenue_report AS
SELECT o.order_date, SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_date;

-- 20) REGEXP (extra string skill): emails with non .com TLDs
SELECT customer_id, email
FROM customers
WHERE email REGEXP '\.[a-z]{2,}$' AND email NOT LIKE '%.com'
ORDER BY customer_id;
