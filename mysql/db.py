"""
This script connects to a MySQL database, creates tables, and inserts data
using SQL scripts.

## Key Features:
- Automatically connects to a MySQL database using environment variables for \
    configuration.
- Creates the database if it does not exist.
- Executes schema creation and data insertion using \
    SQL scripts (`schema.sql` and `queries.sql`).
- Logs all operations and errors to both the console \
    and a log file (`cpy-errors.log`).
- Uses `mysql.connector` for database operations and \
    `tabulate` for pretty-printing query results.
- Supports retry logic for database connection with \
    configurable attempts and delays.
- Handles MySQL-specific errors gracefully, including \
    database and table existence checks.
- Provides a clear, tabulated view of database contents after operations.

## Assumptions:
- MySQL Shell is installed and accessible for executing \
    complex SQL scripts (e.g., procedures, triggers).
- Environment variables for database connection details \
    are defined in a `.env` file or system environment.
- SQL scripts:
    - `schema.sql`: Contains commands to create tables, triggers, indexes, and views.
    - `queries.sql`: Contains commands to insert or update data in the database.
- The script is intended to be run as a standalone program.

## Usage:
1. Ensure the required environment variables are set:
     - `MYSQL_DATABASE`, `MYSQL_HOST`, `MYSQL_USER`, `MYSQL_PORT`, `MYSQL_PASSWORD`.
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
import time

import mysql.connector as mysql
from mysql.connector import errorcode
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

TEST_COMPLETION_TIME = 3  # in seconds

# .env file variables
MYSQL_DATABASE = os.environ.get("MYSQL_DATABASE", default="ems")
MYSQL_HOST = os.environ.get("MYSQL_HOST", default="db")
MYSQL_USER = os.environ.get("MYSQL_USER", default="root")
MYSQL_PORT = os.environ.get("MYSQL_PORT", default=3306)
MYSQL_PASSWORD = os.environ.get("MYSQL_PASSWORD")
RAISE_ON_WARNINGS = bool(os.environ.get("RAISE_ON_WARNINGS", default=True))

# MySQL database configuration
conn_config = {
    "user": MYSQL_USER,
    "password": MYSQL_PASSWORD,
    "host": MYSQL_HOST,
    "port": MYSQL_PORT,
    "raise_on_warnings": RAISE_ON_WARNINGS,
}

db_config = {
    "database": MYSQL_DATABASE,
}

config = {**conn_config, **db_config}


def create_database() -> None:
    """Create database if it doesn't exist"""
    cnx = None
    cursor = None
    try:
        logger.info("Creating database: %s", MYSQL_DATABASE)
        cnx = mysql.connect(**conn_config)

        cursor = cnx.cursor()
        cursor.execute(f"CREATE DATABASE `{MYSQL_DATABASE}`;")
        # NO fetch nedded cursor.fetchall()
    except mysql.Error as err:
        if err.errno == errorcode.ER_DB_CREATE_EXISTS:
            logger.info("Database already exists")
        else:
            logger.info(f"Error creating database: {MYSQL_DATABASE}, {err}")
            raise
    finally:
        logger.info("Database created successfully.")
        if cursor:
            cursor.close()
        if cnx:
            cnx.commit()
            cnx.close()


def connect_to_mysql(
    config: dict, attempts: int = 3, delay: int = 2
) -> mysql.MySQLConnection:
    """Connect to the mysql database (create if it doesn't exist)
    - Catch any errors that occur during the connection attempt

    Args:
        config (int): connection configuration
        attempts (int, optional): try to reconnect how many times. Defaults to 3.
        delay (int, optional): delay between attempts in seconds. Defaults to 2.

    Returns:
        mysql.connector.connection.MySQLConnection: connection object
    """
    attempt = 1
    # Implement a reconnection routine
    while attempt < attempts + 1:
        try:
            return mysql.connect(**config)
        except (mysql.Error, IOError) as err:
            if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
                logger.info("Something is wrong with your user name or password", err)
                break
            elif err.errno in [
                errorcode.ER_BAD_DB_ERROR,
                errorcode.ER_NO_DB_ERROR,
            ]:
                logger.info("Database does not exist %s", err)
                create_database()
                # return mysql.connect(**config)

            if attempts is attempt:
                # Attempts to reconnect failed; returning None
                logger.info("Failed to connect, exiting without a connection: %s", err)
                break
            logger.info(
                "Connection failed: %s. Retrying (%d/%d)...",
                err,
                attempt,
                attempts - 1,
            )
            # progressive reconnect delay
            time.sleep(delay**attempt)
            attempt += 1
    logger.info("Failed to connect, exiting without a connection.")
    return None


cnx = connect_to_mysql(config)
if cnx is None:
    logger.info("Failed to connect to the database. Exiting...")
    exit(1)
else:
    logger.info("Connected to the database successfully.")


def get_cursor(
    cnx: mysql.MySQLConnection = cnx, bufferd: bool = False
) -> mysql.cursor.MySQLCursor:
    """Get a cursor from the connection object

    Args:
        cnx (mysql.MySQLConnection): connection object

    Returns:
        mysql.cursor.MySQLCursor: cursor object
    """
    try:
        return cnx.cursor(buffered=bufferd)
    except mysql.Error as err:
        logger.info("Error getting cursor: %s", err)
        raise


def pretty_list(cursor):
    for item in cursor:
        print(f"-{item[0]}")


def run_create_schema_subprocess() -> None:
    """Create schema using mysql-shell
    - Avoids mysql connector delimiter problem for procedure and triggers.
    - Uses host to connect with mysql-server.
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
        f"mysql -h{MYSQL_HOST} -u{MYSQL_USER} -p{MYSQL_PASSWORD} ems < ./schema.sql",
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
    db = get_cursor()
    print("Connected to MYSQL server.")
    db.execute("SHOW TABLES;")
    tables = db.fetchall()
    if not tables:
        logger.info(f"Database `{name}` is empty. No tables found.")
        run_create_schema_subprocess()
        db.execute("SHOW TABLES")
        tables = db.fetchall()

    logger.info(f"Tables created in `{name}` database (count:{len(tables)})")
    db.close()  # Close the cursor before committing
    cnx.commit()


def pretty_print_table(cursor, state):
    # Fetch all rows from the cursor
    try:
        rows = cursor.fetchall()
    except mysql.ProgrammingError:
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
                cursor = get_cursor()
                cursor.execute(query)
                # Only print if it's a SELECT statement or potentially modifies data
                # (heuristic: check if cursor.description is set after execute)
                if cursor.description:
                    pretty_print_table(cursor, query.strip())
                else:
                    # For non-SELECT, print the query itself for context
                    print(f"\n\nEXECUTED: {query.strip()}")
            except mysql.Error as e:
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

    time.sleep(TEST_COMPLETION_TIME)
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
        cursor = get_cursor()
        # After schema creation, re-fetch tables
        cursor.execute("SHOW DATABASES;")
        databases = cursor.fetchall()
        pretty_list(databases)
        # After schema creation, re-fetch tables
        cursor.execute("SHOW TABLES;")
        tables = cursor.fetchall()
        print(f"Tables in `{name}` the database (count:{len(tables)}):")
        pretty_list(tables)
    except mysql.Error as e:
        logger.error(f"Could not fetch table names: {e}")
    finally:
        if cursor:
            cursor.close()
        if cnx:
            cnx.commit()


if __name__ == "__main__":
    create_schema(MYSQL_DATABASE)
    insert_and_update(MYSQL_DATABASE)
    if cnx:
        cnx.close()
