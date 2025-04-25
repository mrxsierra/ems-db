import logging
import sqlite3

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


def pretty_print_table(cursor, name=""):
    # Fetch all rows from the cursor
    rows = cursor.fetchall()
    if not rows:
        return
    # Get the column names from the cursor description
    headers = [description[0] for description in cursor.description]

    # Print the table using tabulate
    print(f"\n\nSTATEMENT: {name}")
    print(tb(rows, headers, tablefmt="grid"))


def create_database_and_tables():
    """Create a SQLite database and execute SQL scripts \
        to create tables and insert data.
    This script connects to an SQLite database, reads SQL scripts from files,
    executes them to create tables and insert data, and then fetches and displays
    the contents of the few tables.
    - The script also prints the names of all tables in the database.
    - It uses the sqlite3 library to interact with the database and the tabulate
    library to format the output in a readable table format.
    - The script is intended to be run as a standalone program.
    - It creates a database file named 'ems.db' in the current directory.
    - The SQL scripts should be located in the same directory as this script.
    - The script assumes that the SQL scripts are named 'schema.sql' and 'queries.sql'.
    - The 'schema.sql' file should contain the SQL commands to create the necessary \
        tables,
    and the 'queries.sql' file should contain the SQL commands to insert data \
        into those tables.
    - The script also fetches and displays the contents of the 'students', 'tests', \
        and 'tests_sessions' tables.
    - It prints the names of all tables in the database at the end.
    """

    # Connect to the SQLite database (create if it doesn't exist)
    connection = sqlite3.connect("ems.db")
    logger.info("Connected to the database successfully.")

    print("Hello from `ems` db!")

    # Create a cursor object
    cursor = connection.cursor()

    # Open and read the SQL file
    with open("schema.sql", "r") as sql_file:
        sql_schema_script = sql_file.read()

    # Execute the SQL scripts for creating tables and inserting data
    cursor.executescript(sql_schema_script)
    logger.info("Tables created successfully.")

    print("\n\nLet's Insert Some Data replicating user flow: ...")

    # Open and read the SQL file
    with open("queries.sql", "r") as sql_file:
        sql_queries_script = sql_file.read()

    # Execute the SQL scripts for inserting data
    for query in sql_queries_script.split(";"):
        cursor.execute(query)
        pretty_print_table(cursor, query)
    logger.info("Data inserted and updated sucessfully .")

    # fetch some tables
    cursor.execute("SELECT * FROM students")
    pretty_print_table(cursor, "Students")

    cursor.execute("SELECT * FROM tests")
    pretty_print_table(cursor, "Tests")

    cursor.execute("SELECT * FROM tests_sessions")
    pretty_print_table(cursor, "Tests Sessions")

    logger.info("Bye from ems-db!")
    print("Further Explore Using `sqlite3 Shell`")

    # Query the sqlite_master table to get table names
    result = cursor.execute(
        "SELECT name from sqlite_master where type = 'table' or type = 'view';"
    )
    tables = [row[0] for row in result]

    # Print the list of tables
    print("Tables in the database:")
    for table in tables:
        print(f"- {table}")

    # Commit the transaction (if required)
    connection.commit()

    # Close the connection
    connection.close()


if __name__ == "__main__":
    create_database_and_tables()
