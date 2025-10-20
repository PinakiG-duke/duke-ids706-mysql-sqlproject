
-- MySQL 8.0+ Setup Script
-- Schema: Simple Retail (normalized) with FKs and sample constraints
-- Run this in MySQL Workbench / DBeaver / VS Code SQL client.

DROP DATABASE IF EXISTS retail_demo;
CREATE DATABASE retail_demo CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE retail_demo;

-- Safety: drop in dependency order
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS stores;

CREATE TABLE stores (
    store_id     INT PRIMARY KEY,
    store_name   VARCHAR(100) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    state        VARCHAR(50)  NOT NULL
) ENGINE=InnoDB;

CREATE TABLE customers (
    customer_id  INT PRIMARY KEY,
    first_name   VARCHAR(80)  NOT NULL,
    last_name    VARCHAR(80)  NOT NULL,
    email        VARCHAR(255) NOT NULL UNIQUE,
    created_at   DATE NOT NULL DEFAULT (CURRENT_DATE)
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id   INT PRIMARY KEY,
    sku          VARCHAR(50) NOT NULL UNIQUE,
    product_name VARCHAR(150) NOT NULL,
    category     VARCHAR(80)  NOT NULL,
    unit_price   DECIMAL(10,2) NOT NULL,
    meta         JSON NULL,                      -- extra feature: JSON column for tags/specs
    CHECK (unit_price >= 0)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id     INT PRIMARY KEY,
    customer_id  INT NOT NULL,
    store_id     INT NOT NULL,
    order_date   DATE NOT NULL,
    status       ENUM('PLACED','PAID','SHIPPED','DELIVERED','CANCELLED') NOT NULL,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_orders_store    FOREIGN KEY (store_id)    REFERENCES stores(store_id)
) ENGINE=InnoDB;

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id      INT NOT NULL,
    product_id    INT NOT NULL,
    quantity      INT NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    CONSTRAINT fk_oi_order   FOREIGN KEY (order_id)  REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_oi_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    CHECK (quantity > 0),
    CHECK (unit_price >= 0)
) ENGINE=InnoDB;

CREATE TABLE payments (
    payment_id   INT PRIMARY KEY,
    order_id     INT NOT NULL,
    amount       DECIMAL(10,2) NOT NULL,
    method       ENUM('CARD','CASH','WALLET','BANK') NOT NULL,
    paid_at      DATETIME NOT NULL,
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    CHECK (amount >= 0)
) ENGINE=InnoDB;

-- Seed data
INSERT INTO stores (store_id, store_name, city, state) VALUES
(1,'Downtown Durham','Durham','NC'),
(2,'Chapel Hill Central','Chapel Hill','NC'),
(3,'RTP Express','Raleigh','NC');

INSERT INTO customers (customer_id, first_name, last_name, email, created_at) VALUES
(1,'Asha','Rao','asha.rao@example.com','2025-09-01'),
(2,'Ben','Kim','ben.kim@example.com','2025-09-10'),
(3,'Carlos','Diaz','carlos.diaz@example.com','2025-09-15'),
(4,'Dina','Singh','dina.singh@example.com','2025-09-20');

INSERT INTO products (product_id, sku, product_name, category, unit_price, meta) VALUES
(1,'SKU-COF-001','Cold Brew Coffee','Beverages',4.99, JSON_OBJECT('tags', JSON_ARRAY('drink','cold'))),
(2,'SKU-TBR-002','Protein Bar','Snacks',2.49, JSON_OBJECT('protein_g', 20, 'vegan', false)),
(3,'SKU-APL-003','Gala Apple','Produce',0.79, JSON_OBJECT('origin','USA')),
(4,'SKU-YGT-004','Greek Yogurt','Dairy',1.19, JSON_OBJECT('fat_pct',0)),
(5,'SKU-RCE-005','Basmati Rice (2lb)','Pantry',5.49, JSON_OBJECT('basmati', true));

INSERT INTO orders (order_id, customer_id, store_id, order_date, status) VALUES
(101,1,1,'2025-09-21','PAID'),
(102,1,1,'2025-09-22','DELIVERED'),
(103,2,2,'2025-09-22','PAID'),
(104,2,2,'2025-09-25','CANCELLED'),
(105,3,3,'2025-10-01','SHIPPED'),
(106,3,1,'2025-10-02','PLACED'),
(107,4,1,'2025-10-03','PAID');

INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price) VALUES
(1,101,1,2,4.99),
(2,101,2,3,2.49),
(3,102,3,5,0.79),
(4,103,5,1,5.49),
(5,103,4,4,1.19),
(6,104,2,10,2.39),
(7,105,1,1,4.89),
(8,105,5,2,5.39),
(9,106,3,10,0.75),
(10,107,2,2,2.49),
(11,107,4,2,1.09);

INSERT INTO payments (payment_id, order_id, amount, method, paid_at) VALUES
(9001,101, (2*4.99 + 3*2.49), 'CARD',  '2025-09-21 10:15:00'),
(9002,102, (5*0.79),          'CASH',  '2025-09-22 12:01:00'),
(9003,103, (1*5.49 + 4*1.19), 'CARD',  '2025-09-22 15:45:33'),
(9004,105, (1*4.89 + 2*5.39), 'BANK',  '2025-10-01 09:25:00'),
(9005,107, (2*2.49 + 2*1.09), 'WALLET','2025-10-03 18:05:00');

-- DML example: simulate a price increase for snacks
UPDATE products SET unit_price = unit_price * 1.02 WHERE category = 'Snacks';

-- Helpful indexes (optional, interview-ready)
CREATE INDEX idx_orders_date       ON orders(order_date);
CREATE INDEX idx_oi_order          ON order_items(order_id);
CREATE INDEX idx_oi_product        ON order_items(product_id);
CREATE INDEX idx_pay_order         ON payments(order_id);
