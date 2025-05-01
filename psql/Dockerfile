# syntax=docker/dockerfile:1
ARG PYTHON_VERSION

# ------------------- Base build stage ------------------------- 
# Use a specific uv version tag for better reproducibility
FROM ghcr.io/astral-sh/uv:0.6.16-debian-slim AS base

# Install PostgreSQL client using the PostgreSQL APT repository
RUN apt-get update && \
    apt-get install -y wget gnupg2 && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y postgresql-client-17 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Only use the managed Python version
ENV UV_PYTHON_PREFERENCE=only-managed
# Configure the Python directory so it is consistent
ENV UV_PYTHON_INSTALL_DIR=/python
# Prepend venv and tool bin to PATH for immediate use
ENV PATH="/app/.venv/bin:/root/.local/bin:${PATH}"

# Install Python before the project for caching
RUN uv python install ${PYTHON_VERSION}

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

# --- Set root password (SECURITY RISK!) ---
# WARNING: Hardcoding passwords is insecure. Use only for local dev.
# Replace 'your_secure_root_password' with a password you choose.
# RUN echo 'root:your_secure_root_password' | chpasswd

# -------------------- Development Stage ------------------------
FROM base AS dev

# Create a non-root user for development (best practice for isolation)
# useradd -p flag can be used for pass
ARG USER
ARG DEV_UID
ARG DEV_GID
ARG PGHOST
ARG PGPORT
ARG PGDATABASE
ARG PGUSER
ARG PGPASSWORD

RUN groupadd --gid ${DEV_GID} devuser && \
    useradd --uid ${DEV_UID} --gid ${DEV_GID} --create-home devuser

# Automatically activate the virtual environment on container start
# Best way for credentials saving at root dir with restrictive access
# \npassword=$PGPASSWORD
RUN for file in ~/.bashrc /home/${USER}/.bashrc; do \
    echo "source /app/.venv/bin/activate" >> $file && \
    echo "export PGSERVICE=my$PGHOST" >> $file; \
    done && \
    for file in ~/.pg_service.conf /home/${USER}/.pg_service.conf; do \
    echo "[my${PGHOST}]\nhost=$PGHOST\nport=$PGPORT\ndbname=$PGDATABASE\nuser=$PGUSER" >> $file; \
    done && \ 
    for file in ~/.pgpass /home/${USER}/.pgpass; do \
    echo "$PGHOST:$PGPORT:$PGDATABASE:$PGUSER:$PGPASSWORD" >> $file; \
    chmod 600 $file; \
    done && \
    chown ${USER}:${DEV_GID} /home/${USER}/.pgpass

# Not ideal but work in dev env
# ENV PGPASSWORD="secret"

# Default
USER ${USER}
WORKDIR /app

# Copy only project definition files initially for efficient caching
COPY pyproject.toml uv.lock* ./

# Install development dependencies using cache mounts
RUN --mount=type=cache,id=uv-cache-dev-ems-psql-${PYTHON_VERSION},target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen

# Copy the rest of the application code
COPY . .

# Default command to keep the development container running
CMD ["tail", "-f", "/dev/null"]

EXPOSE 3000
