# Usage

`Postgres`

***`Prerequisites`***:
Ensure the following tools are installed on your system:

>- **Python**: for scripting.
>- **Postgres-Server**: for database management.
>- **Postgres Client/Shell** 🌟: `Optional` but `Required` for administrative tasks like interacting with Postgres databases.

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

> ***Ensure :*** `CWD` is `/ems-db/psql` or `/app` in case of docker `tty`.

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

- **Ensure :** `PWD` is `ems-db/psql` for current terminal session.
- This, runs ***only few*** sample queries in db.

> `You can RUN` directly this CMD below! if your `virtual env` is sorted or activated.

```py
# step 1-2 create db using `schema.sql` & run sample queries
uv run db.py
# or equivalent if not using uv
python db.py
```

> **IMPORTANT :** Use `psql shell` for `running all spectrum of queries` from `queries.sql`.

### Using psql shell

#### ***Step: 1*** `Create Database` and `Activate` `psql shell` in `python env`

```sh
# Create & Open db in psql shell session
psql -a -b ems postgres
```

- Use flag `-a` to `echo` all input from script
- Use flag `-b` to `echo` failed commands
- Use db name `ems` as ***new or existing database***.

> **Note :** `Next steps` will be Executed in `psql shell`.

#### ***Step: 2*** `Create database schema`

```sh title="psql shell"
\i ./schema.sql
# or direct cli equivalent
psql -a -b ems postgres < ./schema.sql
```

> **Note :** CMD `\i` is `psql shell` CMD for `sql` file batch execution.

#### ***Step: 3*** `Query Database`

```sh title="psql shell"
# Explore database
\i ./queries.sql
# or direct cli equivalent
psql -a -b ems postgres < ./queries.sql
```

#### `Exit` ***psql Shell Session***

```sh title="psql shell"
\q
# or equivalent
exit
```

## Quick Explore

Postgres Cli and Shell Interface Interactions.

### Without psql shell

> `client` using flag `-c`

```sh
psql -a -b ems postgres -c "SHOW TABLES;"
# Multiple client CMD's
musql -a -b ems postgres -c '\c ems', '\i schema.sql', '\i queries.sql', '\l', '\dt', 'SELECT * FROM `students`', '\q'
```

> ***Note :*** Commands `example` above are also `in sequence` for single execution of operation.

### With psql shell

> ***`Note:`*** psql `shell session` ***: a terminal like session*** can be started using `psql cli`. Using cli `CMD's` eg.

```sh title="psql-shell"
psql -h[HOST] -U[USER_NAME] [Your-Database-Name]
```

```sh title="psql-cli-help"
# psql CLI help
psql -?
# or equivalent
psql --help
```

#### Inside shell session

Some CMD's eg. may look like.

```sh title="psql-shell"
# check databases
\l;
# check tables
\dt;
# change database
\c [DATABASE_NAME]
# Select
SELECT * FROM table_name;
# running script
\i [file.sql]
# exit
\q
# help
\?

# Other 
\du
\dp
\drg
\dg
\dT
```

For more see [Postgres Commands](#postgres) references below👇.

## References

- [`UV` Working on projects](https://docs.astral.sh/uv/guides/projects/)

### Postgres

- [Postgres Client Reference](https://www.postgresql.org/docs/17/reference-client.html)
- [Postgres Book Indexes](https://www.postgresql.org/docs/17/bookindex.html)
- [Postgres Book](https://www.postgresql.org/docs/current/index.html)

### Installation

- [Python Downloads Page](https://www.python.org/downloads/)
- [Postgres Downloads Page](https://www.postgresql.org/download/)
- [Docker Installation Guide](https://docs.docker.com/get-docker/)
- [UV Installation Guide](https://docs.astral.sh/uv/getting-started/installation/)

> **Note**: Verify the installations by running the respective version commands, e.g., `python --version`, `psql --version`, `docker --version`, and `uv --version`.

### Reads

- [Syntax Differences b/w Databases for Migration - `CS50S Notes`](https://cs50.harvard.edu/sql/2024/notes/6/#postgresql)
- [Postgres Commands](https://www.postgresql.org/docs/current/sql-commands.html)
- [Postgres Date and Time Functions](https://www.postgresql.org/docs/17/functions-datetime.html)
- [Postgres Triggers and Trigger Functions](https://www.postgresql.org/docs/17/plpgsql-trigger.html)
- [Postgres Set Statements](https://www.postgresql.org/docs/current/sql-set.html)
- [Postgres Data Types](https://www.postgresql.org/docs/current/datatype.html)
- [psycopg3 Documentation](https://www.psycopg.org/psycopg3/docs/basic/usage.html)
