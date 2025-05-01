# Starting This Project with Docker

`sqlite`

Talks about container development environment setups and use.

- ***Prerequisites :*** `Docker`

## Quick Overview 🚀

- **Dockerfile**: Defines how to build the container image.
- **compose.yml**: Configures and runs the container services.

### Key Highlights ✨

- **Live Code Updates**: Host workdir is mounted to `/app` in the `app` service. Changes reflect instantly.
- **Virtual Environment Caching**: Runtime `.venv` is cached separately to avoid unnecessary rebuilds.
- **Optimized Builds**: Tracks `pyproject.toml` and `uv.lock` for faster dependency updates.

> **No Setup Hassle**: Skip installing `Python`, `sqlite-shell`, or `uv`. It's all in the container! 🐳

Thanks to Docker files 🤩...

## Getting Started

When you're ready, start your application from `docker files dir` as a `root` or `workdir`.

> eg. `PWD`: `ems-db/mysql`

then use `Steps`:

### `Step-1`

- Starts `app` service defined in `compose.yml`.
- `Compose up` builds and Runs new container image and mounts `PWD` as volume.
- Uses `detach mode` flag `-d` and `--build` for ensuring building new images instead of cached if dependencies changes.

> **Note :** Code changes will be reflected instantly.

```sh
# First time new build or to update dependencies changes
docker compose up --build -d

# Later utilising cache for fast build
docker compose up -d

# Verify using listing active or stopped services
docker ps
```

> ***Stop/Clean UP :*** Use `docker compose down`, it uses compose def like above just inversely.
>
> - ADD `-v` flag for volume.
> - Add `--rmi` flag for removing images, `Not Recommended` unless you want update to different docker image version or performing deep clean up.
>

### `Step-2`

- Opens interactive `tty` (terminal session) for running command
- Using `exec` `bash` cmd `for terminal session` inside `app` services.

> ***Syntex :*** `docker compose exec [SERVICE] [COMMANDS]`

```sh
# Launch Interactive service tty
docker compose exec app bash
# exit from tty
exit

# or direct run and exists tty
docker compose exec app [COMMANDS]
```

### eg. `Run db.py`

- Uses `uv` env and package manager
- Setups env & packages
- Runs `db.py`

```sh
# From tty
uv run db.py

# or direct and exists
docker compose exec app uv run db.py
```

### eg. `For Sqlite Shell Interaction`

- Using `sqlite3` cli
- Start sqlite shell session for `ems.db`
- flags are used for better output and debug experiances

```sh
# From tty
sqlite3 ems.db -table -echo

# or direct run and exists tty
docker compose exec app sqlite3 ems.db -table -echo
# exit sqlite shell
# since we are in [Entry Command Line]->[container tty shell]->{mysql shell}
.exit
```

> `For More` continue reading mysql [`usage.md`](usage.md#getting-started) | [#Getting Started Section](usage.md#first-activate-venv).

### Help Commands

```sh
# Check list of active or stopped service
docker ps
# available images
docker images
# as a root user
docker compose exec -u root app bash 
# help
docker --help
```

## References

- [Docker Manuals](https://docs.docker.com/build/concepts/dockerfile/)
- [Docker Cheatsheet](https://docs.docker.com/get-started/docker_cheatsheet.pdf)

### Images Info

- [uv](https://docs.astral.sh/uv/guides/integration/docker/)

### Reads

- [Docker's Python guide](https://docs.docker.com/language/python/)
- [Docker Quick workshop](https://docs.docker.com/get-started/workshop/)
- [Compose Getting Started](https://docs.docker.com/compose/gettingstarted/)
- [Compose Volumes](https://docs.docker.com/reference/compose-file/volumes/)
- [Use Compose Watch](https://docs.docker.com/compose/how-tos/file-watch/)
