# Usage

`MySQL`

***`Prerequisites`***:
Ensure the following tools are installed on your system:

>- **Python**: for scripting.
>- **MYSQL-Server**: for database management.
>- **MySQL Client/Shell** 🌟: `Optional` but `Required` for administrative tasks like interacting with MySQL databases.

---
> **Optional**
>
>- **Docker** : `Installed and running` useful for containerized environments.
>- **UV** : A utility for Python package and project management.

---
`Wanna Save Time`:

- Use Docker! For Skipping all!
- For removing complexity and reproducibility, This approach is `RECOMMENDED`.
- Read [Starting This Project with Docker](README.Docker.md). Than come back Here.

See [Installations References](#installation) below at the end of page.

## Getting started

***For Docker***

- Execute `Steps 1 & 2` from [Starting This Project with Docker](README.Docker.md#step-1) before moving further.
- This will setup system level project environment for developing in container.
- plus, it will land you in `container terminal session` in `/app` working/project dir
- plus, it will activate `.venv` for you.

> ***Ensure :*** `CWD` is `/ems-db/mysql` or `/app` in case of docker `tty`.

### Using python scripts

#### ***First***: `Activate .venv`

- Using uv `RUN` create and activate `.venv` for running python scripts.

> Skip this step in case of `using docker dev environment`.  

```sh
# Using uv this create and activate python .venv
# using `pyroject.toml` and `uv.lock`
uv run
# or 
uv sync

# activate venv win
.venv\Scripts\activate
# or use linux cmd to activate .venv
source .venv/bin/activate

# deactivate .venv
deactivate
```

#### ***Second***: `Run script`

- **Ensure :** `PWD` is `ems-db/mysql` for current terminal session.
- This, runs ***only few*** sample queries in db.

> `You can RUN` directly this CMD below! if your `virtual env` is sorted or activated.

```py
# step 1-2 create db using `schema.sql` & run sample queries
uv run db.py
# or equivalent if not using uv
python db.py
```

> **IMPORTANT :** Use `mysql shell` for `running all spectrum of queries` from `queries.sql`.

### Using mysql shell

#### ***Step: 1*** `Create Database` and `Activate` `mysql shell` in `python env`

```sh
# Create & Open db in mysql shell session
mysql -t -v -uroot -psecret ems
```

- Use flag `-t` as ***output mode set to table*** for better readability.
- Use flag `-v` to ***verbose*** for better debugging.
- Use db_name `ems` as ***new or existing database***.

> **Note :** `Next steps` will be Executed in `mysql shell`.

#### ***Step: 2*** `Create database schema`

```sh title="mysql shell"
source ./schema.sql
# or direct cli equivalent
mysql -tv -uroot -psecret ems < ./schema.sql
```

> **Note :** CMD `.read` is `mysql shell` CMD for `sql` file batch execution.

#### ***Step: 3*** `Query Database`

```sh title="mysql shell"
# Explore database
source ./queries.sql
# or direct cli equivalent
mysql -tv -uroot -psecret ems < ./queries.sql
```

#### `Exit` ***mysql Shell Session***

```sh title="mysql shell"
\q
# or equivalent
exit
```

## Quick Explore

MySQL Cli and Shell Interface Interactions.

### Without mysql shell

> `client` using flag `-e`

```sh
mysql -t -uroot -psecret ems -e "SHOW TABLES;"
# Multiple client CMD's
musql -t -uroot -usecret ems -e 'use ems', '.mode table', 'source schema.sql', 'source queries.sql', 'show databases', 'show tables', '.schema', 'SELECT * FROM `students`', '\q'
```

> ***Note :*** Commands `example` above are also `in sequence` for single execution of operation.

### With mysql shell

> ***`Note:`*** mysql `shell session` ***: a terminal like session*** can be started using `mysql cli`. Using cli `CMD's` eg.

```sh title="mysql-shell"
mysql -h[HOST] -u[USER_NAME] -p[USER_PASSWORD] [Your-Database-Name]
```

```sh title="mysql-cli-help"
# MYSQL CLI help
mysql -?
# or equivalent
mysql --help
```

#### Inside shell session

Some CMD's eg. may look like.

```sh title="mysql-shell"
# check databases
SHOW DATABASES;
# check tables
SHOW TABLES;
# change database
use [DATABASE_NAME]
# Select
SELECT * FROM table_name;
# running script
source [file.sql]
# exit
\q
# help
\?

# administrative
SHOW GRANTS FOR [user];
SHOW PRIVILEGES;
SHOW PROFILES;
SHOW STATUS;

# check silent errors
SHOW WARNINGS;
SHOW ERRORS;

# table
SHOW OPEN TABLES FROM [db_name];
SHOW TABLE STATUS FROM [db_name];
SHOW FULL TABLES FROM [db_name];
SHOW FULL COLUMNS FROM tbl_name FROM [db_name] [like_or_where];

SHOW TRIGGERS FROM [db_name];

# schema
SHOW CREATE DATABASE [db_name];
SHOW CREATE EVENT [event_name];
SHOW CREATE FUNCTION [func_name];
SHOW CREATE PROCEDURE [proc_name];
SHOW CREATE TABLE [tbl_name];
SHOW CREATE TRIGGER [trigger_name];
SHOW CREATE VIEW [view_name];
```

For more see [Commands](#mysql) references below👇.

## References

- [`UV` Working on projects](https://docs.astral.sh/uv/guides/projects/)

### MySQL

- [MySQL Cli/Shell Show Commands](https://dev.mysql.com/doc/refman/8.0/en/show.html)

### Installation

- [Python Downloads Page](https://www.python.org/downloads/)
- [MySQL-Server-Installation](https://dev.mysql.com/doc/refman/8.4/en/installing.html)
- [MYSQL Client/Shell Installation](https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-shell-install.html)
- [Docker Installation Guide](https://docs.docker.com/get-docker/)
- [UV Installation Guide](https://docs.astral.sh/uv/getting-started/installation/)

> **Note**: Verify the installations by running the respective version commands, e.g., `python --version`, `mysql --version`, `docker --version`, and `uv --version`.

### Reads

- [Syntax Differences b/w Databases for Migration - `CS50S Notes`](https://cs50.harvard.edu/sql/2024/notes/6/#mysql)
- [Using Data Types from Other Database Engines](https://dev.mysql.com/doc/refman/8.0/en/other-vendor-data-types.html)
- [Date and Time Functions](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html)
- [Data Definition Statements](https://dev.mysql.com/doc/refman/8.0/en/sql-data-definition-statements.html)
- [mysql-connector-python](https://dev.mysql.com/doc/connector-python/en/connector-python-example-connecting.html)
