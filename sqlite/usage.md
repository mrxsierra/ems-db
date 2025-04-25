# Usage

`SQLite3`

***`Prerequisites`***:
Ensure the following tools are installed on your system:

>- **Python**: SQLite comes pre-installed with Python.
>- **SQLite Client/Shell** 🌟: `Optional` but `Required` for administrative tasks like interacting with SQLite databases.

---
> **Optional**
>
>- **Docker** : `Installed and running` useful for containerized environments.
>- **UV** : A utility for Python package and project management.

---
`Wanna Save Time`:

- Use Docker!
- Read [Starting This Project with Docker](README.Docker.md). Than come back Here.

See [Installtions References](#installation) below at the end of page.

## Getting started

***For Docker***

- Execute `Steps 1 & 2` from [Starting This Project with Docker](README.Docker.md#step-1) before moving further.
- This will setup system level project environment for developing in container.
- plus, it will land you in `container terminal session` in `/app` working/project dir
- plus, it will activate `.venv` for you.

> ***Ensure :*** `CWD` is `/ems-db/sqlite` or `/app` in case of docker `tty`.

### Using python scripts

#### ***First***: `Activate venv`

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

- **Ensure :** `PWD` is `ems-db/sqlite` for current terminal session.
- This, runs ***only few*** sample queries in db.

> `You can RUN` directly this CMD below! if your `virtual env` is sorted or activated.

```py
# step 1-2 create db using `schema.sql` & run sample queries
uv run db.py
# or equivalent if not using uv
python db.py
```

> **IMPORTANT :** Use `sqlite shell` for `running all spectrum of queries` from `queries.sql`.

### Using sqlite shell

#### ***Step: 1*** `Create Database` and `Acivate` `sqlite3 shell` in `python env`

```sh
# Create & Open db in sqlite3 shell session
sqlite3 -table -echo ems.db 
```

- Use flag `-table` as ***output mode*** for better readability.
- Use flag `-echo` to ***print input before executing*** for better debugging.
- Use filename `ems.db` as ***new or existing database***.

> **Note :** `Next steps` will be Excuted in `sqlite3 shell`.

#### ***Step: 2*** `Create database schema`

```sh title="sqlite3 shell"
.read ./schema.sql
# or direct cli equivalent
sqlite3 -echo -table ems.db < ./schema.sql
```

> **Note :** CMD `.read` is `sqlite3 shell` CMD for `sql` file batch execution.

#### ***Step: 3*** `Query Database`

```sh title="sqlite3 shell"
# Explore database
.read ./queries.sql
# or direct cli equivalent
sqlite3 -echo -table ems < ./queries.sql
```

#### `Exit` ***sqlite3 Shell Session***

```sh title="sqlite3 shell"
.exit
# or equivalent
.quit
```

## Quick Explore

SQlite3 Cli and Shell Interface Interactions.

### Without sqlite3 shell

> `client` using flag `-cmd`

```sh
# Multiple client CMD's
sqlite3 ems.db -cmd '.echo on', '.mode table', '.read schema.sql', '.read queries.sql', '.databases', '.tables', '.schema', 'SELECT * FROM "students"', '.exit'
```

> ***Note :*** Commands `example` above are also `in sequence` for single execution of operation.

### With sqlite3 shell

> ***`Note:`*** sqlite3 `shell session` ***: a terminal like session*** can be started using `sqlite3 cli`. Using cli `CMD's` eg.

```sh
sqlite3 [Your-Database-Name].db
```

#### Inside shell session

Some CMD's eg. may look like.

```sh title="sqlite3 shell"
# check databases
.databases
# check schema
.schema
# check tables
.tables
# Select
SELECT * FROM table_name;
# exit
.exit
# help
.help
```

For more see [Commands](#sqlite3) references below👇.

## References

- [`UV` Working on projects](https://docs.astral.sh/uv/guides/projects/)

### SQlite3

- [SQlite3 cli/shell Commands](https://sqlite.org/cli.html)

### Installation

- [Python Downloads Page](https://www.python.org/downloads/)
- [SQLite Download Page](https://www.sqlite.org/download.html)
- [Docker Installation Guide](https://docs.docker.com/get-docker/)
- [UV Installation Guide](https://docs.astral.sh/uv/getting-started/installation/)

> **Note**: Verify the installations by running the respective version commands, e.g., `python --version`, `sqlite3 --version`, `docker --version`, and `uv --version`.

### Reads

- [Creating a Database Schema](https://cs50.harvard.edu/sql/2024/notes/2/#creating-a-database-schema)
- [Syntax differences for MySQL! - `Migration`](https://cs50.harvard.edu/sql/2024/notes/6/#mysql)
- [SQL As Understood By SQLite](https://sqlite.org/lang.html)
- [SQLite Module Python Doc](https://docs.python.org/3/library/sqlite3.html)
