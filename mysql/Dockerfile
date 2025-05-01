# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.13

# ------------------- Base build stage ------------------------- 
# Use a specific uv version tag for better reproducibility
FROM ghcr.io/astral-sh/uv:debian-slim AS base

# Add MySQL APT repository
RUN apt update -y && \
    apt install -y wget lsb-release gnupg && \
    wget https://dev.mysql.com/get/mysql-apt-config_0.8.34-1_all.deb && \
    DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.34-1_all.deb && \
    apt update -y && \
    apt install -y mysql-shell && \
    rm -f mysql-apt-config_0.8.34-1_all.deb &&\
    apt clean && rm -rf /var/lib/apt/lists/*


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
ARG DEV_UID=1000
ARG DEV_GID=1000
ARG USER=devuser
ARG MYSQL_USER
ARG MYSQL_PASSWORD
ARG MYSQL_HOST
ARG MYSQL_DATABASE

RUN groupadd --gid ${DEV_GID} ${USER} && \
    useradd --uid ${DEV_UID} --gid ${DEV_GID} --create-home devuser

# Automate .venv activation
# alias mysqlsh to mysqls
# setup mysql config for auto login
RUN for file in /home/devuser/.bashrc ~/.bashrc; do \
    echo "source /app/.venv/bin/activate" >> $file && \
    echo "alias mysql='mysqlsh'" >> $file; \
    done && \
    for file in ~/.my.cnf /home/${USER}/.my.cnf; do \
    echo "[client]\nuser=$MYSQL_USER\npassword=$MYSQL_PASSWORD\nhost=$MYSQL_HOST\ndatabase=$MYSQL_DATABASE" >> $file && \
    chmod 600 $file; \
    done && \
    chown ${USER}:${DEV_GID} /home/${USER}/.my.cnf

# Default
USER ${USER}
WORKDIR /app

# Copy only project definition files initially for efficient caching
COPY pyproject.toml uv.lock* ./

# Install development dependencies using cache mounts
RUN --mount=type=cache,id=uv-cache-dev-ems-mysql-${PYTHON_VERSION},target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen

# Copy the rest of the application code
COPY . .

# Default command to keep the development container running
CMD ["tail", "-f", "/dev/null"]

EXPOSE 3000
