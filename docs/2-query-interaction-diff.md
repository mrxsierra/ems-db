<!-- markdownlint-disable MD041 -->
Okay, building on our previous discussion about SQL schema differences, let's dive into how we interact with `SQLite`, `MySQL`, and `PostgreSQL`, focusing on query execution, CLI usage, and connection methods.

This companion blog post will use the **`queries.sql`, `README.Docker.md`, and `usage.md`** files from the [Exam Management System (EMS)](https://github.com/mrxsierra/ems-db/) project as our practical examples.

- ***Project Repo :*** [ems-db](https://github.com/mrxsierra/ems-db/) **`<-- root-dir-name`**

> If you missed the first part on schema definitions, you can catch up here:

- [Navigating the Nuances: A Developer's Guide to SQL Dialects (SQLite, MySQL, PostgreSQL)](/1-schema_diff.md).

This post will serve as another handy reference, highlighting the practical differences you'll encounter when running queries and managing these databases, especially useful for both day-to-day development and for showcasing practical database skills.

> **Drill**
>
> - ***Warning :** Refer to `Official Docs`, when in doubt. **`"Its not ultimate source of truth. It could be good starting point."`***
> - ***Understanding :*** Use [this project](https://github.com/mrxsierra/ems-db/) as reference.
> - ***Prerequisites :*** Familiar with `sql syntax`, `client interaction`, `Docker`, and `Python` (language of choice).

# Beyond the Schema: A Practical Guide to Querying and Interacting with SQLite, MySQL, & PostgreSQL

In our [previous post](/1-schema_diff.md), we explored the key differences in schema definitions across `SQLite`, `MySQL`, and `PostgreSQL` using the [Exam Management System (EMS)](https://github.com/mrxsierra/ems-db/) project as a case study.

Now, let's shift our focus to the equally important aspects of how we *interact* with these databases: ***running queries, using their command-line interfaces (CLIs), and understanding connection nuances, especially in a Dockerized environment.***

> *This guide draws insights from the following project files (within the [ems-db](https://github.com/mrxsierra/ems-db/) repository)*:

- **Query Scripts:**
    - [sqlite/queries.sql](/sqlite/queries.sql)
    - [psql/queries.sql](/psql/queries.sql)
    - [mysql/queries.sql](/mysql/queries.sql)

- **Usage & Docker Documentation:**
    - [sqlite/usage.md](/sqlite/usage.md) & [sqlite/README.Docker.md](/sqlite/README.Docker.md)
    - [psql/usage.md](/psql/usage.md) & [psql/README.Docker.md](/psql/README.Docker.md)
    - [mysql/usage.md](/mysql/usage.md) & [mysql/README.Docker.md](/mysql/README.Docker.md)

Understanding these practical differences can significantly boost your efficiency and adaptability as a developer.

## Key Areas of Difference: Queries & Interaction

### 1. CLI Shell Access & Connection

Each database has its own command-line tool for direct interaction.

- **SQLite:**
    - Command: `sqlite3 ems.db [options]`
    - Example from [`sqlite/usage.md`](/sqlite/usage.md#step-1-create-database-and-acivate-sqlite3-shell-in-python-env): `sqlite3 ems.db -table -echo`
        - `-table`: Sets output mode to table format.
        - `-echo`: Prints commands before execution.
    - Connection is file-based; you specify the database file path.

- **PostgreSQL:**
    - Command: `psql [options] [dbname] [username]`
    - Example from [`psql/usage.md`](/psql/usage.md#step-1-create-database-and-activate-psql-shell-in-python-env): `psql -a -b ems postgres`
        - `-a`: Echoes all input from script.
        - `-b`: Echoes failed commands.
        - `ems`: Database name.
        - `postgres`: Username.
    - In Docker, from an `app` service: `psql -h db ems postgres` (where `db` is the service name of the PostgreSQL container).
    - PostgreSQL's [`README.Docker.md`](/psql/README.Docker.md#extra) also mentions using `~/.pgpass` for passwordless connections in development environments.

- **MySQL:**
    - Command: `mysql [options] -u[user] -p[password] [dbname]`
    - Example from [`mysql/usage.md`](/mysql/usage.md#step-1-create-database-and-activate-mysql-shell-in-python-env): `mysql -t -v -uroot -psecret ems`
        - `-t`: Output in table format.
        - `-v`: Verbose mode.
        - `-uroot -psecret`: Username and password.
        - `ems`: Database name (as defined in `compose.yml` `MYSQL_DATABASE` env var).
    - MySQL's [`README.Docker.md`](/mysql/README.Docker.md#app-service-too-has-mysqlsh-mysql-shell-install-for-quick-interaction) also mentions `mysqlsh` as a more powerful alternative shell, aliased as `mysql` in the `app` service. Often used for connecting with `cloud native mysql server` from `client machines`.

> 🔍 **Tip**: All three databases differ significantly in how they let you inspect objects (like tables, views, indexes) from shell clients—see section 5 and beyond.

### 2. Executing SQL Scripts from Files

Running a series of SQL commands from a `.sql` file is a common task.

- **SQLite:**
    - Shell command: `.read ./queries.sql`
    - CLI redirection: `sqlite3 ems.db -table -echo < ./queries.sql`

> As seen in [`sqlite/usage.md`](/sqlite/usage.md#step-2-create-database-schema) and [`sqlite/queries.sql`](/sqlite/queries.sql)

- **PostgreSQL:**
    - Shell command: `\i ./queries.sql`
    - CLI redirection: `psql -a -b ems postgres < ./queries.sql`

> As seen in [`psql/usage.md`](/psql/usage.md#step-2-create-database-schema) and [`psql/queries.sql`](/psql/queries.sql)

- **MySQL:**
    - Shell command: `source ./queries.sql`
    - CLI redirection: `mysql -tv -uroot -psecret ems < ./queries.sql`

> 🧩 **Important**: When schema files contain stored procedures, triggers, or functions that require `DELIMITER`, executing them inside the `mysql` CLI is more reliable than using `mysql-connector-python` (which doesn't support `DELIMITER`). This limitation makes shell execution the preferred approach for complex DDL.
>
> As seen in [`mysql/usage.md`](/mysql/usage.md#step-2-create-database-schema) and [`mysql/queries.sql`](/mysql/queries.sql)

### 3. Resetting Auto-Increment Values

After clearing tables (e.g., with `DELETE FROM table;`), you often want to reset auto-increment counters for primary keys, especially during development or testing.

- **SQLite:**
    - If `AUTOINCREMENT` keyword is used on an `INTEGER PRIMARY KEY` column, SQLite uses an internal table `sqlite_sequence`.
        - To reset: `DELETE FROM sqlite_sequence WHERE name='your_table_name';`
    - The [`sqlite/queries.sql`](/sqlite/queries.sql) file simply uses `DELETE FROM students;`. If `AUTOINCREMENT` was *not* explicitly used (as in the `students` table in the provided schema), SQLite might reuse IDs from deleted rows. For a true reset, the `sqlite_sequence` table would need to be managed if `AUTOINCREMENT` was present.

- **PostgreSQL:**
    - Uses sequences. The `SERIAL` type automatically creates a sequence suffixed with `_id_seq`.
    - Command from [`psql/queries.sql`](/psql/queries.sql): `ALTER SEQUENCE students_id_seq RESTART WITH 1;`

- **MySQL:**
    - Command from [`mysql/queries.sql`](/mysql/queries.sql): `ALTER TABLE students AUTO_INCREMENT = 1;`

### 4. Data Manipulation Language (DML) Snippets

The basic syntax for `INSERT`, `UPDATE`, and `DELETE` is highly standardized. The `queries.sql` files for all three databases demonstrate this:

- **INSERT:**

    ```sql
    -- Common across SQLite, PostgreSQL, MySQL (quoting may vary per schema)
    INSERT INTO students (first_name, last_name, password, email)
    VALUES ('John', 'Doe', 'password123', 'john.doe@example.com');
    ```

- **UPDATE:**

    ```sql
    -- Common across SQLite, PostgreSQL, MySQL (quoting may vary per schema)
    UPDATE tests_sessions
    SET status = 'completed'
    WHERE id = 1;
    ```

- **DELETE (Clearing a table):**

    ```sql
    -- Common across SQLite, PostgreSQL, MySQL
    DELETE FROM reports;
    ```

> ***Identifier quoting :*** `Double quotes for SQLite/PostgreSQL`, `backticks for MySQL` discussed in the [schema blog](./1-schema-diff.md#1-dropping-objects-tables-views-indexes) post also applies here.

### 5. Querying Data & Analysis (SELECT, EXPLAIN)

Standard `SELECT` statements with `JOINs`, `WHERE` clauses, and subqueries are largely portable.

- **Example SELECT (from [`sqlite/queries.sql`](/sqlite/queries.sql), similar in others):**

    ```sql
    SELECT *
    FROM tests_history
    WHERE student_id = (
        SELECT id
        FROM students
        WHERE email = 'john.doe@example.com'
    );
    ```

- **Inspecting Tables/Views/Indexes (within shell clients):**

    - **SQLite**:
        - List tables: `.tables`
        - View DDL: `.schema table_name` or full schema: `.fullschema`
        - List indexes:  
          `SELECT name FROM sqlite_master WHERE type='index';`

    - **PostgreSQL**:
        - List tables: `\dt`
        - View indexes: `\di`
        - View DDL: `\d+ table_name` or for indexes/views: `\d+ index_name`, `\d+ view_name`
        - SQL alternatives:

          ```sql
          SELECT * FROM information_schema.tables WHERE table_schema='public';
          SELECT * FROM pg_indexes WHERE schemaname = 'public';
          ```

    - **MySQL**:
        - List tables: `SHOW TABLES;`
        - List indexes: `SHOW INDEX FROM table_name;`
        - List views:

          ```sql
          SHOW FULL TABLES WHERE TABLE_TYPE = 'VIEW';
          SHOW CREATE VIEW view_name;
          ```

        - SQL alternatives via `information_schema`:

          ```sql
          SELECT * FROM information_schema.tables WHERE table_schema = 'your_db';
          SELECT * FROM information_schema.statistics WHERE table_schema = 'your_db';
          ```

- **Query Plan Analysis:**
    - **SQLite:** `EXPLAIN QUERY PLAN SELECT ...;` (as used in comments in [`sqlite/queries.sql`](/sqlite/queries.sql) `#Line-151 or below`).
    - **PostgreSQL & MySQL:** `EXPLAIN SELECT ...;` (This is the standard command, though not explicitly run in the provided `queries.sql` files for PSQL/MySQL, it's the common way to analyze queries for better indexing and performance optimizations).

### 6. Dialect-Specific Functions/Commands in Queries

While core SQL is similar, some functions or commands are unique.

- **SQLite:** Uses functions like `STRFTIME()` and `DATETIME()` for date/time manipulations (more prominent in its [`schema.sql`](/sqlite/schema.sql)) triggers).
- **PostgreSQL:** Rich set of functions; `INTERVAL` arithmetic is a key feature (seen in its `schema.sql` triggers). The [`queries.sql`](/psql/queries.sql) uses standard SQL.
- **MySQL:**
    - `SLEEP(seconds)`: Used in [`mysql/queries.sql`](/mysql/queries.sql) (`SELECT SLEEP(3);`) to pause execution, often for testing or simulation.
    - `TIMEDIFF()`: Used in its [`schema.sql`](/mysql/schema.sql) trigger.

### 7. Error Handling & Diagnostics (CLI/SQL)

- **SQLite:**
    - CLI: `-echo` flag helps trace execution.

- **PostgreSQL:**
    - CLI: `-a` (echo all) and `-b` (echo errors) flags.
    - Shell: `\set ON_ERROR_STOP on` can be useful in scripts.

- **MySQL:**
    - SQL Commands: `SHOW ERRORS;` and `SHOW WARNINGS;` are explicitly used in `mysql/queries.sql` to check for issues after operations.
    - CLI: `-v` (verbose) flag.

### 8. Exiting Shells

- **SQLite:** `.exit` or `.quit`
- **PostgreSQL:** `\q` or `exit`
- **MySQL:** `\q` or `exit` (or `quit`)

### 9. Python Script Interaction (Brief)

The `usage.md` files for each database mention running a `db.py` script (e.g., `uv run db.py`). While this post focuses on CLI interaction, it's important to note that these databases are typically accessed programmatically via Python using libraries:

- **SQLite:** `sqlite3` (standard library)
- **PostgreSQL:** `psycopg2` or `psycopg` (third-party)
- **MySQL:** `mysql-connector-python` or `PyMySQL` (third-party)
These libraries handle connection and query execution, abstracting some dialect specifics but still requiring correct SQL syntax for the target database.

> **MySQL Note:** As mentioned earlier, MySQL's `mysql-connector-python` does not support the `DELIMITER` command needed for procedures/triggers. This makes CLI-based execution of `schema.sql` safer and more portable.

### 10. Docker Environment Nuances

The `README.Docker.md` files highlight how Docker simplifies setup and interaction:

- **Universal Access:** `docker compose exec [service_name] bash` provides a shell within the container, from which you can then launch the respective database CLI.
    - SQLite: `docker compose exec app bash` then `sqlite3 ems.db`
    - PostgreSQL: `docker compose exec db bash` then `psql ...` or `docker compose exec app bash` then `psql -h db ...`
    - MySQL: `docker compose exec db bash` then `mysql ...` or `docker compose exec app bash` then `mysql ...` (often `mysqlsh` aliased as `mysql`).
    - **Service Discovery:** For PostgreSQL and MySQL, the database often runs in a service named `db` (as defined in `compose.yml`), accessible from an `app` service using this hostname (e.g., `psql -h db ...`).
- **Pre-configured Environments:** Docker setups often pre-configure users, passwords, and databases (e.g., `MYSQL_ROOT_PASSWORD`, `POSTGRES_USER`, `POSTGRES_DB` environment variables in `compose.yml`).
- **SQL Dump Mounting:** `README.Docker.md` for PostgreSQL and MySQL mentions mounting SQL dumps for pre-seeding data, which automates schema creation and initial data insertion on container startup.
- **GUI Tools:**
    - PostgreSQL: `adminer` service often included for web-based DB management.
    - MySQL: `phpmyadmin` service often included.

## Quick Cheatsheet: Query & Interaction

| Feature                 | SQLite                                     | PostgreSQL                                         | MySQL                                                  |
|-------------------------|--------------------------------------------|----------------------------------------------------|-------------------------------------------------------|
| **CLI Tool**            | `sqlite3`                                  | `psql`                                             | `mysql`, `mysqlsh`(for client)                                    |
| **Connect (Example)**   | `sqlite3 ems.db`                           | `psql -U user -d dbname`                           | `mysql -u user -p pass dbname`                        |
| **Run SQL File (Shell)**| `.read file.sql`                           | `\i file.sql`                                      | `source file.sql`                                     |
| **Run SQL File (CLI)**  | `sqlite3 db < file.sql`                    | `psql ... < file.sql`                              | `mysql ... < file.sql`                                |
| **Reset Auto-Increment**| `DELETE FROM sqlite_sequence WHERE name='tbl';` (if `AUTOINCREMENT` used) | `ALTER SEQUENCE seq_name RESTART WITH 1;`        | `ALTER TABLE tbl AUTO_INCREMENT = 1;`               |
| **Query Plan**          | `EXPLAIN QUERY PLAN ...`                   | `EXPLAIN ...`                                      | `EXPLAIN ...`                                         |
| **Show Errors (SQL)**   | N/A (check return codes/messages)          | N/A (check messages, `ON_ERROR_STOP`)              | `SHOW ERRORS;`, `SHOW WARNINGS;`                      |
| **Exit Shell**          | `.exit`, `.quit`                           | `\q`, `exit`                                       | `\q`, `exit`, `quit`                                  |
| **Docker Exec (App)**   | `docker compose exec app sqlite3 ...`      | `docker compose exec app psql -h db ...`           | `docker compose exec app mysql -h db ...`             |
| **Docker Exec (DB)**    | `docker compose exec db sqlite3 ...`       | `docker compose exec db psql ...`                  | `docker compose exec db mysql ...`                     |
| **View Tables (Shell)** | `.tables`                                  | `\dt`                                              | `SHOW TABLES;`                                        |
| **View Indexes (Shell)**| Query `sqlite_master`                      | `\di`                                              | `SHOW INDEX FROM tbl;`                                |

## Why This Matters

**For Developers:**

- **Efficiency:** Knowing the right CLI commands, flags, and shell directives saves significant time during development and debugging.
- **Scripting & Automation:** Understanding how to execute SQL files and manage database states (like resetting sequences) is crucial for automated testing and deployment.
- **Tooling:** Familiarity with Docker interaction patterns and GUI tools enhances the development workflow.
- **Debugging:** Using `EXPLAIN` and error-checking commands helps optimize queries and troubleshoot issues effectively.

**Learning:**

- **Practical Skills:** These interaction nuances demonstrate hands-on experience beyond theoretical SQL knowledge.
- **Versatility:** Comfort with different database CLIs and Docker environments indicates adaptability.
- **Problem-Solving:** The ability to diagnose query performance or script execution issues points to strong troubleshooting skills.

## Conclusion

Mastering the art of SQL goes beyond writing `SELECT` statements. **It encompasses how you connect to your database, execute scripts, analyze performance, and manage its state through various tools and environments.** As demonstrated by the [`Exam Management System (ems-db)`](https://github.com/mrxsierra/ems-db/) project's supporting files, ***each database system—SQLite, MySQL, and PostgreSQL—offers a slightly different, yet powerful, set of tools and commands for these tasks***.

By familiarizing yourself with these practical aspects, you become a more well-rounded and effective data professional.

***Happy querying***!

---

> ***Disclaimer**: The examples are drawn from specific project files and general knowledge. Always refer to the official documentation for the most comprehensive and up-to-date information.*

## References & Resources

This section compiles useful links found within the [`ems-db`](https://github.com/mrxsierra/ems-db/) project's documentation (`usage.md`, `README.Docker.md` files), categorized for easier navigation.

### General

- **Docker:**
    - [Docker Manuals](https://docs.docker.com/build/concepts/dockerfile/)
    - [Docker Cheatsheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)
    - [Docker's Python guide](https://docs.docker.com/language/python/)
    - [Docker Quick workshop](https://docs.docker.com/get-started/workshop/)
    - [Compose Getting Started](https://docs.docker.com/compose/gettingstarted/)
    - [Compose Volumes](https://docs.docker.com/reference/compose-file/volumes/)
    - [Use Compose Watch](https://docs.docker.com/compose/how-tos/file-watch/)
- **UV (Python Packager):**
    - [UV: Working on projects](https://docs.astral.sh/uv/guides/projects/)
    - [UV: Docker Integration](https://docs.astral.sh/uv/guides/integration/docker/)
- **CS50 SQL Notes (General Syntax Differences):**
    - [MySQL Differences](https://cs50.harvard.edu/sql/2024/notes/6/#mysql)
    - [PostgreSQL Differences](https://cs50.harvard.edu/sql/2024/notes/6/#postgresql)

### SQLite

- [SQLite CLI Commands](https://sqlite.org/cli.html)
- [SQL As Understood By SQLite](https://sqlite.org/lang.html)
- [Python `sqlite3` Module](https://docs.python.org/3/library/sqlite3.html)
- [SQLite Download Page](https://www.sqlite.org/download.html)

### PostgreSQL

- **Client & Server Documentation:**
    - [Postgres Client Reference](https://www.postgresql.org/docs/17/reference-client.html)
    - [Postgres SQL Commands](https://www.postgresql.org/docs/current/sql-commands.html)
    - [Postgres Date and Time Functions](https://www.postgresql.org/docs/17/functions-datetime.html)
    - [Postgres Environment Variables](https://www.postgresql.org/docs/17/libpq-envars.html)
    - [Postgres Connection Strings](https://www.postgresql.org/docs/17/libpq-connect.html#LIBPQ-CONNSTRING)
    - [Postgres Passwords File (`.pgpass`)](https://www.postgresql.org/docs/17/libpq-pgpass.html)
- **Python Driver:** [psycopg3 Documentation](https://www.psycopg.org/psycopg3/docs/basic/usage.html)
- **Docker Hub:** [Postgres Image](https://hub.docker.com/_/postgres)
- [Postgres Download Page](https://www.postgresql.org/download/)

### MySQL

- **MySQL Documentation:**
    - [MySQL SHOW Commands](https://dev.mysql.com/doc/refman/8.0/en/show.html)
    - [Date and Time Functions](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html)
    - [Docker MySQL Deployment Topics](https://dev.mysql.com/doc/refman/8.4/en/docker-mysql-more-topics.html)
    - [mysqlsh Shell Startup](https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-shell-sessions-startup.html)
- **Python Driver:** [mysql-connector-python](https://dev.mysql.com/doc/connector-python/en/connector-python-example-connecting.html)
- **Docker Hub:** [MySQL Image](https://hub.docker.com/_/mysql)
- [MySQL Server Installation](https://dev.mysql.com/doc/refman/8.4/en/installing.html)
- [MySQL Client/Shell Installation](https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-shell-install.html)

### GUI Tools (mentioned in Docker setups)

- [Adminer (for PostgreSQL & others)](https://hub.docker.com/_/adminer)
- [phpMyAdmin (for MySQL)](https://hub.docker.com/_/phpmyadmin)
