
# SQL Guidebook (MySQL 8.0+) — How to Run & Connect

## 0) Prereqs
- MySQL Server 8.0+ installed (local or remote)
- One of:
  - **VS Code** with either:
    - *SQLTools* extension + *SQLTools MySQL/MariaDB* driver, or
    - *MySQL* (Oracle) extension
  - **MySQL Workbench**
  - **DBeaver Community**

---

## 1) Create the Database & Load Data
Open your SQL client and run:
1. Open `mysql_setup.sql`
2. Execute the whole script (creates `retail_demo`, tables, FKs, seed data, indexes).

> If permissions restrict `DROP DATABASE`, remove the first two lines and run from within an existing schema.

---

## 2) VS Code Connection
### Option A: SQLTools
1. Install **SQLTools** and **SQLTools MySQL/MariaDB** extensions.
2. Press `Cmd/Ctrl+Shift+P` → `SQLTools: Add new connection`.
3. Choose MySQL, enter:
   - **Server**: `localhost`
   - **Port**: `3306`
   - **Database**: `retail_demo`
   - **User**: `<your_user>`
   - **Password**: `<your_pass>`
4. Save. Open a new `.sql` file, select the connection (SQLTools status bar), and **Run Query**.

### Option B: Oracle MySQL Extension
1. Install **MySQL** extension (Oracle).
2. Open the *MySQL* pane → `+` to add connection → fill host/port/user/password.
3. Right-click the connection → *New Query* to open a query editor bound to your database.

---

## 3) MySQL Workbench
1. Open Workbench → `+` to create a new connection → fill host/port/username/password.
2. Connect, open a new SQL tab, and run `mysql_setup.sql`. 
3. Then run `mysql_queries.sql` to see outputs.

---

## 4) DBeaver
1. File → *New* → *Database Connection* → MySQL.
2. Fill host/port/credentials → Test Connection → Finish.
3. Right-click `retail_demo` → *SQL Editor* → run scripts.

---

## 5) Run the Query Pack
- Open `mysql_queries.sql` in your SQL client.
- Ensure you're using: `USE retail_demo;`
- Execute all or run query-by-query.

---

## 6) What’s Included (aligned to rubric)
- **DDL & DML**: `CREATE TABLE`, `INSERT`, `UPDATE` (incl. `UPDATE ... JOIN`), CTAS
- **Basics**: `SELECT`, `FROM`, `WHERE`, `ORDER BY`, `GROUP BY`, `LIMIT`, `HAVING`
- **Aggregates**: `SUM`, `COUNT`, `AVG`, `MAX/MIN`
- **JOINs**: `INNER`, `LEFT`, `RIGHT`, FULL OUTER emulation
- **Cleaning/Transform**: `CASE WHEN`, `COALESCE`, string ops, `REGEXP`
- **Window**: `ROW_NUMBER`, `DENSE_RANK`, `LAG`, `LEAD`, rolling sums
- **CTEs**: non-recursive + **recursive** (date calendar)
- **Extra features**: `JSON` type + `JSON_EXTRACT/JSON_CONTAINS`, `REGEXP`, date formats
- **Set ops**: `UNION`, EXCEPT emulation via `NOT EXISTS`

If you hit errors, confirm your MySQL version is 8.0+ and that `USE retail_demo;` is set.
