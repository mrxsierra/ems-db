# syntax=docker/dockerfile:1
ARG PYTHON_VERSION=3.13

# Use a specific uv version tag for better reproducibility
FROM ghcr.io/astral-sh/uv:debian-slim AS base

# Add SQLite3-shell
RUN apt update -y && apt install -y sqlite3 && \
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

# ------------------------ Development Stage ------------------------------
FROM base AS dev
WORKDIR /app

# Copy only project definition files initially for efficient caching
COPY pyproject.toml uv.lock* ./

# Install development dependencies using cache mounts
RUN --mount=type=cache,id=uv-cache-dev-ems-sqlite-${PYTHON_VERSION},target=/root/.cache/uv \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    uv sync --frozen

# Copy the rest of the application code
COPY . .

# Create a non-root user for development (best practice for isolation)
ARG DEV_UID=1000
ARG DEV_GID=1000
RUN groupadd --gid ${DEV_GID} devuser && \
    useradd --uid ${DEV_UID} --gid ${DEV_GID} --create-home devuser
USER devuser

# Automatically activate the virtual environment on container start
RUN echo "source /app/.venv/bin/activate" >> /home/devuser/.bashrc

# Default command to keep the development container running
CMD ["tail", "-f", "/dev/null"]
