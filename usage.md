# Usage

## sqlite3

> - ***Requirements:*** `python`
> - **Note:** sqlite comes pre-installed with python.

### ***Step: 1*** `Create Database` and `Acivate` `sqlite3 shell` in `python env`.

>- Use flag `-table` as ***output mode*** for better readability.
>- Use flag `-echo` to ***print input before executing*** for better debugging.
>- Use filename `ems.db` as ***new or existing database***.

`RUN`

```sh
# Using uv
uv run sqlite3 -table -echo ems.db
```

`OR RUN`

```sh
# Activate python env and run
sqlite3 -table -echo ems.db
```

> ***`NOTE:`*** `Next steps` will be Excuted in `sqlite3 shell`.

### ***Step: 2*** `Create database schema`

```sh title="sqlite3 shell"
.read ./schema.sql
```

> ***`NOTE:`*** CMD `.read` is `sqlite3 shell` CMD

### ***Step: 3*** `Query Database`

```sh title="sqlite3 shell"
.read ./queries.sql
```

### `Exit` ***sqlite3 Shell***

```sh title="sqlite3 shell"
.exit
# or
.quit
```

### Quick Explore

#### Without sqlite3 shell

> using flag `-cmd`

```sh
# Multiple CMD's
sqlite3 ems.db -cmd '.echo on', '.mode table', '.read schema.sql', '.read queries.sql', '.databases', '.tables', '.schema', 'SELECT * FROM "students"', '.exit'
```

#### With sqlite3 shell

- check tables

```sh title="sqlite3 shell"
.tables
```

- check databases

```sh title="sqlite3 shell"
.databases
```

- check schema

```sh title="sqlite3 shell"
.schema
```
