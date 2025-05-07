# Starting This Project with Docker

`mysql`

Talks about container development environment setups and use.

- ***Prerequisites :*** `Docker`

## Quick Overview 🚀

- **Dockerfile**: Defines how to build the container image.
- **compose.yml**: Configures and runs the container services.

### Key Highlights ✨

- **Live Code Updates**: Host workdir is mounted to `/app` in the `app` service. Changes reflect instantly.
- **Virtual Environment Caching**: `.venv` is cached separately to avoid unnecessary rebuilds.
- **Optimized Builds**: Tracks `pyproject.toml` and `uv.lock` for faster dependency updates.
- **Mounts SQL Dumps**: Create schema and Insert data for pre-seeding.

> **No Setup Hassle**: Skip installing `Python`, `MySQL with shell`, or `uv`. It's all in the container! 🐳

Thanks to Docker files 🤩...

## Getting Started

When you're ready, start your application from `docker files dir` as a `root` or `workdir`.

> eg. `PWD`: `ems-db/mysql`

then use `Steps`:

### `Step-1`

- Starts `app` & `db` service defined in `compose.yml`.
- `Compose up` builds and Runs new container image and mounts `PWD` as volume.
- Uses `detach mode` flag `-d` and `--build` for ensuring building new images instead of cached if dependencies changes.

> **Note :** Code changes will be reflected.

```sh
# First time new build or anytime to reflect dependencies changes
docker compose up --build -d

# Later utilising cache for fast build
docker compose up -d

# Verify using listing active or stopped services
docker ps -a
```

> ***Stop/Clean UP :*** Use `docker compose down`, it uses compose def like above just inversely.
>
> - ADD `-v` flag for volume.
> - Add `--rmi` flag for removing images, `Not Recommended` unless you want update to different version or performing deep clean up.

### `Step-2`

- Opens interactive `tty` (terminal session) for running command
- Using `exec` `bash` cmd for terminal session inside `app` or `db` service.

> ***Syntex :*** `docker compose exec [SERVICE] [COMMANDS]`

```sh
# Launch interective tty 
## app service
docker compose exec app bash
## or db service
docker compose exec db bash
## For tty service exit
exit

# or direct run after exits tty
## app service
docker compose exec app [COMMAND]
## db service
docker compose exec db [COMMAND]
```

### eg. `Run db.py`

- Uses `uv` env and package manager.
- Setups env & packages.
- Runs `db.py`.

```sh
# From tty
uv run db.py

# or direct run and exits tty
docker compose exec app uv run db.py
```

### eg. `For mysql Shell Interaction`

- Using `mysql` cli.
- Start mysql shell session for `ems` database.
- flags are used for better output and debug experiances.

```sh
# From tty
mysql -t -v -uroot -psecret ems

# or direct run after exit tty
docker compose exec db mysql -t -v -uroot -psecret ems
# exit from mysql shell
# since we are in [Entry Command Line]->[container tty shell]->{mysql shell}
\q
```

> `For More` continue reading mysql [`usage.md`](/usage.md) | [#Getting Started Section](usage.md#first-activate-venv).

### Help Commands

```sh
# Check created service status running or stopped
docker ps -a
# available images
docker images
# as a root user
docker compose exec -u root app bash 
# help
docker --help
```

### Extra

#### ***`db`*** service has `two mysql-shell` its `default from docker mysql` image

> You can choose anyone you want they have same functionality with some caviats.

- `mysql`: light one.
- `mysqlsh`: more powerful one.

e.g `mysqlsh`

```sh
# From tty
mysqlsh --mysqlx -uroot -psecret ems
```

#### **`app`** service too has `mysqlsh` mysql-shell install for quick interaction

- `mysqlsh` aliased `mysql` for consistency.

#### **phpmyadmin** for database gui service access at `db.localhost`

#### **traefik** as reverse proxy service for network communication

## References

- [docker manuals](https://docs.docker.com/build/concepts/dockerfile/)
- [docker cheatsheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)

### Images info

- [mysql](https://hub.docker.com/_/mysql)
- [phpmyadmin](https://hub.docker.com/_/phpmyadmin)
- [uv](https://docs.astral.sh/uv/guides/integration/docker/)
- [traefik](https://hub.docker.com/_/traefik)

### Reads

- [Docker's Python guide](https://docs.docker.com/language/python/)
- [Docker Quick workshop](https://docs.docker.com/get-started/workshop/)
- [Compose Getting Started](https://docs.docker.com/compose/gettingstarted/)
- [Compose Volumes](https://docs.docker.com/reference/compose-file/volumes/)
- [Use Compose Watch](https://docs.docker.com/compose/how-tos/file-watch/)
- [Docker MySQL Deployement Topics - MySQL Docs](https://dev.mysql.com/doc/refman/8.4/en/docker-mysql-more-topics.html)
- [Docker MySQL Basic Steps - MySQL Docs](https://dev.mysql.com/doc/refman/8.4/en/docker-mysql-getting-started.html)
- [mysqlsh shell sessions startup](https://dev.mysql.com/doc/mysql-shell/8.4/en/mysql-shell-sessions-startup.html)
