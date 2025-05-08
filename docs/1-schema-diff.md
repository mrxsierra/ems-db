# Navigating the Nuances: A Developer's Guide to SQL Dialects (SQLite, MySQL, PostgreSQL)

As developers, we often encounter various SQL databases, each with its own flavor of `SQL`. **While the core concepts remain similar, the devil is in the details – especially when it comes to schema definitions, data types, and procedural extensions like triggers.**

**Recently**, while working on an [***`Exam Management System (EMS)`***](https://github.com/mrxsierra/ems-db/), I had the opportunity to define the database schema for `SQLite`, `MySQL`, and `PostgreSQL`. This exercise highlighted some fascinating and crucial differences between these popular relational database management systems (RDBMS).

> **`ℹ️Note` :** **This post aims to serve as a `practical guide` and a bit of a `cheatsheet`, drawing `insights` directly from the `schema` files of project.**

***Project Repo :*** [ems-db](https://github.com/mrxsierra/ems-db/) **`<-- root-dir-name`**

- [sqlite/schema.sql](/sqlite/schema.sql)
- [psql/schema.sql](/psql/schema.sql)
- [mysql/schema.sql](/mysql/schema.sql)

Whether you're a fellow developer looking for a quick reference or trying to gauge a database differences, I hope this comparison proves insightful!

## Key Areas of Difference: Schema

Let's dive into the specific areas where these `SQL dialects` diverge:

> ***Drill***
>>**`⚠️Warning` :** ***Refer to `Official Docs`, when in doubt. `"Its not ultimate source of truth. It could be good starting point."`***
>
> - ***Understanding :*** Use [project](https://github.com/mrxsierra/ems-db/) as reference.
> - ***Prerequisites :*** Familiar with `sql syntax`, `client interaction`, `Docker`, and `Python` (language of choice).

### 1. Dropping Objects (Tables, Views, Indexes)

The syntax for dropping database objects is largely similar, but identifier quoting can vary.

- **SQLite & PostgreSQL:** Use double quotes for identifiers if they contain special characters or are case-sensitive (though often optional).

    ```sql
    -- SQLite & PostgreSQL
    DROP VIEW IF EXISTS "tests_history";
    DROP TABLE IF EXISTS "students";
    ```

- **MySQL:** Uses backticks for identifiers.

    ```sql
    -- MySQL
    DROP VIEW IF EXISTS `tests_history`;
    DROP TABLE IF EXISTS `students`;
    ```

### 2. Data Types and Auto-Incrementing IDs

This is a significant area of divergence.

| Feature             | SQLite                                     | PostgreSQL                                       | MySQL                                           |
|---------------------|--------------------------------------------|--------------------------------------------------|-------------------------------------------------|
| **Auto-Increment ID** | `id INTEGER PRIMARY KEY` (implicitly `AUTOINCREMENT` if it's the primary key and integer type) or explicitly `id INTEGER PRIMARY KEY AUTOINCREMENT` | `id SERIAL PRIMARY KEY` (creates a sequence)     | `id INT AUTO_INCREMENT PRIMARY KEY`             |
| **Text**            | `TEXT`                                     | `VARCHAR(n)`, `TEXT`                             | `VARCHAR(n)`, `TEXT`                            |
| **Integer**         | `INTEGER`                                  | `INTEGER`, `SMALLINT` (for `is_correct`, `score`) | `INT`, `TINYINT(1)` (often for booleans)        |
| **Boolean**         | `INTEGER NOT NULL CHECK ("is_correct" IN (0, 1))` | `SMALLINT NOT NULL DEFAULT 0 CHECK ("is_correct" IN (0, 1))` (or native `BOOLEAN`) | `TINYINT(1) NOT NULL DEFAULT '0'`               |
| **Date/Time**       | `NUMERIC` (stored as text, real, or int), `DATETIME('now', 'localtime')` | `TIMESTAMP WITH TIME ZONE`, `CURRENT_TIMESTAMP` | `DATETIME`, `TIME`, `CURRENT_TIMESTAMP`, `NOW()` |
| **Duration/Interval**| `NUMERIC` (e.g., storing time as text 'HH:MM:SS') | `INTERVAL`                                     | `TIME` (for durations within 24h) or calculate |
| **ENUM Types**      | Simulated with `CHECK` constraint: `CHECK ("status" IN (...))` | Native: `CREATE TYPE "events_type" AS ENUM (...);` | Native: `status ENUM ('active', 'completed')`   |

> **Example: Students Table ID**

- **SQLite:**

    ```sql
    CREATE TABLE "students" (
        "id" INTEGER,
        -- ...
        PRIMARY KEY ("id")
    );
    ```

- **PostgreSQL:**

    ```sql
    CREATE TABLE IF NOT EXISTS "students" (
        "id" SERIAL,
        -- ...
        PRIMARY KEY("id")
    );
    ```

- **MySQL:**

    ```sql
    CREATE TABLE IF NOT EXISTS `students` (
        `id` INT AUTO_INCREMENT,
        -- ...
        PRIMARY KEY (`id`)
    );
    ```

**Example: ENUM for `tests_sessions.status`**

- **SQLite:**

    ```sql
    CREATE TABLE "tests_sessions" (
        -- ...
        "status" TEXT NOT NULL DEFAULT 'in-progress' CHECK (
            "status" IN ('in-progress', 'ended', 'completed')
        )
        -- ...
    );
    ```

- **PostgreSQL:**

    ```sql
    CREATE TYPE "tests_session_status_type" AS ENUM ('in-progress', 'ended', 'completed');
    CREATE TABLE IF NOT EXISTS "tests_sessions" (
        -- ...
        "status" "tests_session_status_type" NOT NULL DEFAULT 'in-progress',
        -- ...
    );
    ```

- **MySQL:**

    ```sql
    CREATE TABLE IF NOT EXISTS `tests_sessions` (
        -- ...
        `status` ENUM ('in-progress', 'ended', 'completed') NOT NULL DEFAULT 'in-progress',
        -- ...
    );
    ```

### 3. Default Values (Especially Timestamps)

- **SQLite:** Uses functions like `DATETIME('now', 'localtime')`.

    ```sql
    "start" NUMERIC NOT NULL DEFAULT (DATETIME('now', 'localtime'))
    ```

- **PostgreSQL:** Uses `CURRENT_TIMESTAMP`.

    ```sql
    "start" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
    ```

- **MySQL:** Uses `CURRENT_TIMESTAMP` or `NOW()`.

    ```sql
    `start` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
    ```

### 4. Trigger Syntax

Triggers are where the syntactical differences become very pronounced.

**Common Goal:** Set the `end` time of a `tests_sessions` row upon insertion, based on the test's duration.

- **SQLite:**

    ```sql
    CREATE TRIGGER "set_end_for_test_session" AFTER INSERT ON "tests_sessions"
    BEGIN
    UPDATE "tests_sessions"
    SET
        "end" = DATETIME(new.start, '+' || (
                SELECT TIME(duration)
                FROM "tests" AS t
                WHERE t."id" = new."test_id"
            ))
    WHERE "id" = new.id;
    END;
    ```

    - Uses `BEGIN...END;` block.
    - `AFTER INSERT`.
    - `new` refers to the inserted row.
    - Date/time arithmetic involves string concatenation for modifiers.

- **PostgreSQL:**

    ```sql
    CREATE OR REPLACE FUNCTION set_end_for_test_session_fn()
    RETURNS TRIGGER AS $$
    BEGIN
        NEW.end := NEW.start + (
            SELECT "duration" FROM "tests" WHERE "id" = NEW.test_id
        );
        RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;

    CREATE TRIGGER "set_end_for_test_session" BEFORE INSERT ON
    "tests_sessions" FOR EACH ROW
    EXECUTE FUNCTION set_end_for_test_session_fn();
    ```

    - Requires a separate trigger function written in a procedural language (e.g., `plpgsql`).
    - `BEFORE INSERT` (can modify `NEW` directly).
    - `FOR EACH ROW` is explicit.
    - `NEW` is a record variable; assignments use `:=`.
    - `RETURN NEW` is crucial for `BEFORE` triggers.
    - Interval arithmetic is more direct (`+ duration`).

- **MySQL:**

    ```sql
    DELIMITER $$
    CREATE TRIGGER `set_end_for_test_session` BEFORE INSERT ON
    `tests_sessions` FOR EACH ROW
    BEGIN
        SET NEW.end = DATE_ADD(
            IFNULL(NEW.start, NOW()), -- NOW() if NEW.start is not yet set
            INTERVAL (
                SELECT TIME_TO_SEC(`duration`) / 60 FROM `tests` WHERE `id` = NEW.`test_id`
            ) MINUTE
        );
    END$$
    DELIMITER ;
    ```

    - Uses `DELIMITER` to define a multi-statement trigger body.
    - `BEFORE INSERT`.
    - `FOR EACH ROW` is explicit.
    - `SET NEW.column = ...` for assignments.
    - Uses functions like `DATE_ADD` and `TIME_TO_SEC` for time arithmetic.

**Key Trigger Differences Summary:**

| Feature          | SQLite                               | PostgreSQL                                     | MySQL                                        |
|------------------|--------------------------------------|------------------------------------------------|----------------------------------------------|
| **Structure**    | `BEGIN...END` directly in trigger    | Separate function + trigger definition         | `DELIMITER $$ BEGIN...END$$ DELIMITER ;`     |
| **Timing**       | `AFTER`/`BEFORE`/`INSTEAD OF`        | `AFTER`/`BEFORE`/`INSTEAD OF`                  | `AFTER`/`BEFORE`                             |
| **Row Reference**| `new`, `old`                         | `NEW`, `OLD` (case-sensitive in PL/pgSQL)      | `NEW`, `OLD`                                 |
| **Modification** | `UPDATE` statement for `AFTER`       | Direct assignment to `NEW` in `BEFORE` trigger | Direct assignment to `NEW` in `BEFORE` trigger |
| **Return Value** | N/A for `AFTER`                      | `RETURN NEW`/`OLD`/`NULL` for `BEFORE`         | N/A                                          |

### 5. Time and Interval Arithmetic

As seen in the trigger examples, how you add durations to timestamps varies:

- **SQLite:** String manipulation with `DATETIME` function modifiers.

    ```sql
    DATETIME(new.start, '+' || (SELECT TIME(duration) ...))
    ```

- **PostgreSQL:** Direct arithmetic with `INTERVAL` types.

    ```sql
    NEW.start + (SELECT "duration" FROM "tests" ...)
    ```

- **MySQL:** Functions like `DATE_ADD()` and `INTERVAL` keyword.

    ```sql
    DATE_ADD(NEW.start, INTERVAL X MINUTE) -- or HOUR, SECOND etc.
    ```

    In my schema, I converted the `TIME` duration to seconds, then to minutes for `DATE_ADD`:

    ```sql
    INTERVAL (SELECT TIME_TO_SEC(`duration`) / 60 FROM `tests` WHERE `id` = NEW.`test_id`) MINUTE
    ```

### 6. Conditional Logic in Triggers/Queries

- **SQLite & MySQL:** `CASE WHEN ... THEN ... ELSE ... END` is standard.
    *SQLite example from `set_score_of_result` trigger:*

    ```sql
    "feedback" = CASE WHEN (...) = 0 THEN 'need-improvement' ELSE 'great' END
    ```

    *MySQL example from `set_score_of_result` trigger:*

    ```sql
    SET NEW.feedback = CASE WHEN (...) = 0 THEN 'need-improvement' ELSE 'great' END;
    ```

- **PostgreSQL:** Supports `CASE` expressions, but also `IF...THEN...ELSE...END IF;` in PL/pgSQL functions.
    *PostgreSQL example from `set_score_of_result_fn` trigger function:*

    ```sql
    IF NEW.score = 0 THEN
        NEW.feedback := 'need-improvement';    
    ELSE
        NEW.feedback := 'great';
    END IF;
    ```

### 7. Handling NULLs in Aggregate Functions

When summing scores, if no results exist for a test session, `SUM()` might return `NULL`.

- **SQLite:** `SUM()` on an empty set returns `NULL`. My schema doesn't explicitly handle this for `final_score` in the trigger, which might be an oversight if a report could be generated before any results.

    ```sql
    (SELECT SUM("results"."score") FROM "results" WHERE "results"."test_session_id" = new.id)
    ```

- **PostgreSQL:** Uses `COALESCE(SUM("score"), 0)` to default to `0` if `SUM` is `NULL`.

    ```sql
    (SELECT COALESCE(SUM("score"),0) FROM "results" WHERE "test_session_id" = NEW.id)
    ```

- **MySQL:** Uses `IFNULL(SUM(\`score\`), 0)` for the same purpose.

    ```sql
    (SELECT IFNULL(SUM(`score`),0) FROM `results` WHERE `test_session_id` = NEW.id)
    ```

### 8. `CREATE TABLE IF NOT EXISTS`

This useful clause prevents errors if a table already exists.

- **SQLite:** Supports `CREATE TABLE IF NOT EXISTS "students" (...)` (though not explicitly used in the provided `students` table creation, it's standard).
- **PostgreSQL:** `CREATE TABLE IF NOT EXISTS "students" (...)`
- **MySQL:** ```CREATE TABLE IF NOT EXISTS `students` (...)```

### 9. Comments

- **SQLite, PostgreSQL, MySQL:** All support `--` for single-line comments.
- **MySQL:** Also supports `#` for single-line comments.

### 10. Index Creation

The basic syntax is similar, but quoting and specific features (like conditional indexing) can differ.

- **SQLite & PostgreSQL:**

    ```sql
    -- SQLite & PostgreSQL
    CREATE INDEX "idx_tests" ON "tests" ("title");
    -- PostgreSQL specific (SQLite also supports WHERE in index but syntax might differ slightly)
    CREATE INDEX "idx_questions_options_is_correct" ON "questions_options" ("is_correct") WHERE "is_correct" = 1;
    ```

- **MySQL:**

    ```sql
    -- MySQL
    CREATE INDEX `idx_tests` ON `tests` (`title`);
    -- MySQL does not directly support WHERE clauses in CREATE INDEX like PostgreSQL/SQLite.
    -- For conditional indexing, you might index the column and rely on the optimizer,
    -- or use generated columns if applicable.
    CREATE INDEX `idx_questions_options_is_correct` ON `questions_options` (`is_correct`);
    ```

### 11. Time Zone Handling

- **SQLite:** `DATETIME('now', 'localtime')` attempts to use local time. Time storage is less strict.
- **PostgreSQL:** Very robust. `TIMESTAMP WITH TIME ZONE` stores timestamps in UTC and converts them to the client's/session's time zone on retrieval. `SET TIME ZONE LOCAL;` can be used.
- **MySQL:** `DATETIME` stores "wall clock" time without time zone info. `TIMESTAMP` converts from current time zone to UTC for storage, and back on retrieval. Session time zone can be set.

## Quick Cheatsheet: SQLite vs. PostgreSQL vs. MySQL

| Feature                 | SQLite                                     | PostgreSQL                                                              | MySQL                                                              |
|-------------------------|--------------------------------------------|-------------------------------------------------------------------------|--------------------------------------------------------------------|
| **Identifier Quoting**  | `"optional"`                               | `"optional/case-sensitive"`                                             | `` `optional` ``                                                   |
| **Auto Increment**      | `INTEGER PRIMARY KEY [AUTOINCREMENT]`      | `SERIAL` or `IDENTITY`                                                  | `INT AUTO_INCREMENT`                                               |
| **Data Types (General)**| Flexible typing (TEXT, NUMERIC, INTEGER)   | Strict, rich types (VARCHAR, TEXT, INT, BIGINT, BOOLEAN, JSON, ARRAY, INTERVAL, ENUM) | Strict types (VARCHAR, TEXT, INT, TINYINT, DATETIME, ENUM, JSON) |
| **ENUMs**               | `CHECK` constraint                         | `CREATE TYPE ... AS ENUM`                                               | `ENUM(...)` column type                                            |
| **Triggers**            | `BEGIN...END`                              | Function-based (`CREATE FUNCTION ... EXECUTE FUNCTION`)                 | `DELIMITER $$ BEGIN...END$$`                                       |
| **Default Timestamp**   | `DATETIME('now', 'localtime')`             | `CURRENT_TIMESTAMP`                                                     | `CURRENT_TIMESTAMP` / `NOW()`                                      |
| **Interval Arithmetic** | String manipulation with `datetime()`      | `+ INTERVAL '...'`                                                      | `DATE_ADD(date, INTERVAL value unit)`                              |
| **Function for NULLs**  | `IFNULL(val, default)` (or `COALESCE`)     | `COALESCE(val, default)`                                                | `IFNULL(val, default)` or `COALESCE(val, default)`                 |

## Why This Matters

**For Developers:**

- **Adaptability:** Understanding these differences allows you to switch between database systems more fluidly.
- **Debugging:** Syntax errors are common when moving SQL code; knowing the nuances helps pinpoint issues faster.
- **Database Design:** Choosing the right data types and features (like native ENUMs or interval types) can lead to a more efficient and maintainable schema.
- **ORM Configuration:** When using Object-Relational Mappers (ORMs), these differences are often abstracted, but knowing what's happening under the hood is invaluable for optimization and complex queries.

**Learnings:**

- **Depth of Understanding:** Articulating these differences helps demonstrating a deeper-than-surface-level understanding of SQL and database systems.
- **Practical Experience:** It often indicates hands-on experience with multiple databases, which is a valuable asset in diverse tech environments.
- **Problem-Solving:** The ability to adapt a schema or queries for different SQL dialects showcases problem-solving skills.

## Next Read 📖

> ***For Debunking** `sql queries` and `clients interaction` differences b/w SQLite, MySQL, and PostgreSQL,*

- `Part-2` **[Beyond the Schema: A Practical Guide to Querying and Interacting with SQLite, MySQL, & PostgreSQL](./2-query-interaction-diff.md)**

> **Note :** It's build upon where this post left.

## Conclusion

While `SQL` is a "standard," its implementations across different RDBMSs like SQLite, MySQL, and PostgreSQL have distinct personalities.

The journey of creating a consistent schema for my [`EMS project`](https://github.com/mrxsierra/ems-db/) across these three was a great learning experience. **Remember, always check the documentation for the specific dialect you're working with.**

I hope this comparative overview helps you in your database endeavors! ***Happy coding***!

---

> ***Disclaimer*** : *The examples are drawn from specific project files and general knowledge. Always refer to the official documentation for the most comprehensive and up-to-date information.*

## References & Resources 🔗

This section compiles useful links found within the [`ems-db`](https://github.com/mrxsierra/ems-db/) project's documentation (`usage.md`, `README.Docker.md` files), categorized for easier navigation.

### General

*CS50 SQL Notes (General Syntax Differences):*

- [MySQL Differences](https://cs50.harvard.edu/sql/2024/notes/6/#mysql)
- [PostgreSQL Differences](https://cs50.harvard.edu/sql/2024/notes/6/#postgresql)

### SQLite

- [SQL As Understood By SQLite](https://sqlite.org/lang.html)
- [Python `sqlite3` Module](https://docs.python.org/3/library/sqlite3.html)

### PostgreSQL

- [Postgres SQL Commands](https://www.postgresql.org/docs/current/sql-commands.html)
- [Postgres Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [Postgres Date and Time Functions](https://www.postgresql.org/docs/17/functions-datetime.html)
- [Postgres Triggers and Trigger Functions](https://www.postgresql.org/docs/17/plpgsql-trigger.html)

### MySQL

- [Using Data Types from Other Database Engines](https://dev.mysql.com/doc/refman/8.0/en/other-vendor-data-types.html)
- [Date and Time Functions](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html)
- [Data Definition Statements](https://dev.mysql.com/doc/refman/8.0/en/sql-data-definition-statements.html)
- [Docker MySQL Basic Steps](https://dev.mysql.com/doc/refman/8.4/en/docker-mysql-getting-started.html)
