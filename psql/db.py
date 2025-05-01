"""
This script connects to a Postgres database, creates tables, and inserts data
using SQL scripts.

## Key Features:
- Automatically connects to a Postgres database using environment variables for \
    configuration.
- Creates the database if it does not exist.
- Executes schema creation and data insertion using \
    SQL scripts (`schema.sql` and `queries.sql`).
- Logs all operations and errors to both the console \
    and a log file (`cpy-errors.log`).
- Uses `psycopg` for database operations and \
    `tabulate` for pretty-printing query results.
- Supports retry logic for database connection with \
    configurable attempts and delays.
- Handles Postgres-specific errors gracefully, including \
    database and table existence checks.
- Provides a clear, tabulated view of database contents after operations.

## Assumptions:
- Postgres Shell is installed and accessible for executing \
    complex SQL scripts (e.g., procedures, triggers).
- Environment variables for database connection details \
    are defined in a `.env` file or system environment.
- SQL scripts:
    - `schema.sql`: Contains commands to create tables, triggers, indexes, and views.
    - `queries.sql`: Contains commands to insert or update data in the database.
- The script is intended to be run as a standalone program.

## Usage:
1. Ensure the required environment variables are set:
     - `POSTGRES_DATABASE`, `POSTGRES_HOST`, `POSTGRES_USER`, `POSTGRES_PORT`, \
         and `POSTGRES_PASSWORD`.
2. Place `schema.sql` and `queries.sql` in the same directory as this script.
3. Run the script to:
     - Create the database and tables (if not already created).
     - Insert or update data in the database.
     - Display the contents of the database in a tabulated format.

## Notes:
- If using Docker Compose, the database schema and data can be \
    initialized using SQL dumps in `/docker-entrypoint-initdb.d`.
- Running this script is optional if the database is already \
    initialized via Docker Compose.
- The script provides additional functionality for managing and \
    inspecting the database programmatically.
"""

import logging
import os
import subprocess
from time import sleep

import psycopg as psql
from tabulate import tabulate as tb

# Set up logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

# Log to console
handler = logging.StreamHandler()
handler.setFormatter(formatter)
logger.addHandler(handler)

# Also log to a file
file_handler = logging.FileHandler("cpy-errors.log")
file_handler.setFormatter(formatter)
logger.addHandler(file_handler)

# In Seconds
TEST_COMPLETION_TIME = 3

# .env file variables
POSTGRES_DATABASE = os.environ.get("POSTGRES_DATABASE", default="ems")
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", default="db")
POSTGRES_USER = os.environ.get("POSTGRES_USER", default="postgres")
POSTGRES_PORT = os.environ.get("POSTGRES_PORT", default=5432)
POSTGRES_PASSWORD = os.environ.get("POSTGRES_PASSWORD")
# RAISE_ON_WARNINGS = bool(os.environ.get("RAISE_ON_WARNINGS", default=True))

# Postgres database configuration
conn_config = {
    "user": POSTGRES_USER,
    "password": POSTGRES_PASSWORD,
    "host": POSTGRES_HOST,
    "port": POSTGRES_PORT,
    # "raise_on_warnings": RAISE_ON_WARNINGS,
}

db_config = {
    "dbname": POSTGRES_DATABASE,
}

config = {**conn_config, **db_config}


def create_database() -> None:
    """Create database if it doesn't exist"""
    cnx = None
    cursor = None
    try:
        logger.info("Creating database: %s", POSTGRES_DATABASE)
        cnx = psql.connect(**conn_config)

        cursor = cnx.cursor()
        cursor.execute(f"CREATE DATABASE {POSTGRES_DATABASE};")
        # No fetchall() needed for CREATE DATABASE
    except psql.errors.DuplicateDatabase:
        logger.info("Database already exists")
    except Exception as err:
        logger.info(f"Error creating database: {POSTGRES_DATABASE}, {err}")
        raise
    finally:
        logger.info("Database creation routine finished.")
        if cursor:
            cursor.close()
        if cnx:
            cnx.commit()
            cnx.close()


def connect_to_psql(config: dict, attempts: int = 3, delay: int = 2) -> psql.Connection:
    """Connect to the Postgres database (create if it doesn't exist)
    - Catch any errors that occur during the connection attempt

    Args:
        config (int): connection configuration
        attempts (int, optional): try to reconnect how many times. Defaults to 3.
        delay (int, optional): delay between attempts in seconds. Defaults to 2.

    Returns:
        psycopg.Connection: connection object
    """
    attempt = 1
    while attempt <= attempts:
        try:
            return psql.connect(**config)
        except psql.OperationalError as e:
            logger.info("OperationalError: %s", e)
            if "does not exist" in str(e):
                logger.info("Database does not exist, attempting to create it.")
                create_database()
                # return psycopg.connect(**config)

            if attempts is attempt:
                # Attempts to reconnect failed; returning None
                logger.info("Failed to connect, exiting without a connection: %s", e)
                break
        except Exception as e:
            logger.info(
                "Connection failed: %s. Retrying (%d/%d)...", e, attempt, attempts
            )
            sleep(delay**attempt)
        attempt += 1
    logger.info("Failed to connect, exiting without a connection.")
    return None


cnx = connect_to_psql(config)
if cnx is None:
    logger.info("Failed to connect to the database. Exiting...")
    exit(1)
else:
    logger.info("Connected to the database successfully.")


def pretty_list(cursor):
    for item in cursor:
        print(f"-{item[0]}")


def run_create_schema_subprocess() -> None:
    """Create schema using psql-shell
    - Uses host to connect with Postgres-server.
    """
    # In this case
    # We just make connection with `db` service as host
    # running in container compose shared network.
    cmd = [
        "docker",
        "compose",
        "exec",
        "db",
        "sh",
        "-c",
        f"PGPASSWORD={POSTGRES_PASSWORD}",
        "psql",
        f"-h {POSTGRES_HOST}",
        f"-U {POSTGRES_USER}",
        f"{POSTGRES_DATABASE} < ./schema.sql",
    ]

    result = subprocess.run(" ".join(cmd), shell=True)

    if result.returncode != 0:
        print("Schema import failed")
        exit(1)
    else:
        print("Schema import succeeded")


def create_schema(name: str = "ems") -> None:
    """Create table schema if it doesn't exist
    - show databases
    - show tables

    Args:
        name (str): database name
    """
    db = cnx.cursor()
    print("Connected to Postgres server.")
    # List tables in the current database using information_schema
    db.execute(
        "SELECT table_name FROM \
            information_schema.tables WHERE table_schema = 'public';"
    )
    tables = db.fetchall()
    if not tables:
        logger.info(f"Database `{name}` is empty. No tables found.")
        run_create_schema_subprocess()
        # After schema creation, re-fetch tables
        db.execute(
            "SELECT table_name FROM \
                information_schema.tables WHERE table_schema = 'public';"
        )
        tables = db.fetchall()

    logger.info(f"Tables created in `{name}` database (count:{len(tables)})")
    db.close()  # Close the cursor before committing
    cnx.commit()


def pretty_print_table(cursor, state):
    # Fetch all rows from the cursor
    try:
        rows = cursor.fetchall()
    except psql.ProgrammingError:
        rows = None
    if rows:
        # Get the column names from the cursor description
        headers = [description[0] for description in cursor.description]
        # Print the table using tabulate
        print(f"\n\n{state}")
        print(tb(rows, headers, tablefmt="grid"))


def execute_and_print(sql_script, script_name=""):
    """Executes SQL queries from a script string and prints results."""
    print(f"\n--- Executing {script_name} ---")
    for query in sql_script.strip().split(";"):
        if query.strip():  # Ensure query is not empty
            try:
                cursor = cnx.cursor()
                cursor.execute(query)
                # Only print if it's a SELECT statement or potentially modifies data
                # (heuristic: check if cursor.description is set after execute)
                if cursor.description:
                    pretty_print_table(cursor, query.strip())
                else:
                    # For non-SELECT, print the query itself for context
                    print(f"\n\nEXECUTED: {query.strip()}")
            except psql.Error as e:
                logger.error(f"Error executing query: {query.strip()}\n{e}")
            finally:
                cursor.close()
                cnx.commit()
    logger.info(f"{script_name} executed successfully.")


def insert_and_update(name: str):
    """Insert and update data in the database
    - Show tables data.
    Args:
        name (str): database name
    """
    print(f"Hello from {name}-db!")

    # Open and read the SQL file
    with open("queries.sql", "r") as queries:
        queries_statements = queries.read()

    query_parts = queries_statements.split("$$$testbreak")
    sql_queries_part1 = query_parts[0]
    sql_queries_part2 = query_parts[1] if len(query_parts) > 1 else ""

    # Execute the first part of the queries script
    execute_and_print(sql_queries_part1, "Queries Part 1 (Inserts/Selects)")

    sleep(TEST_COMPLETION_TIME)
    logger.info(
        f"Sleeping for {TEST_COMPLETION_TIME} seconds to mimic test completion..."
    )

    # Execute the second part of the queries script (if it exists)
    if sql_queries_part2:
        execute_and_print(sql_queries_part2, "Queries Part 2 (Updates/Selects)")

    logger.info("Data inserted and updated successfully.")

    logger.info("Bye from ems-db!")
    print("Further Explore Using `psql Shell`")

    try:
        # After schema creation, re-fetch tables
        cursor = cnx.cursor()
        cursor.execute(
            "SELECT table_name FROM \
                information_schema.tables WHERE table_schema = 'public';"
        )
        tables = cursor.fetchall()
        print(f"Tables in `{name}` the database (count:{len(tables)}):")
        pretty_list(tables)
    except psql.Error as e:
        logger.error(f"Could not fetch table names: {e}")
    finally:
        if cursor:
            cursor.close()
        if cnx:
            cnx.commit()


if __name__ == "__main__":
    create_schema(POSTGRES_DATABASE)
    insert_and_update(POSTGRES_DATABASE)
    if cnx:
        cnx.close()
