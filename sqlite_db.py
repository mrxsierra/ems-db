import sqlite3
from tabulate import tabulate as tb

def pretty_print_table(cursor, name):
    # Fetch all rows from the cursor
    rows = cursor.fetchall()

    # Get the column names from the cursor description
    headers = [description[0] for description in cursor.description]

    # Print the table using tabulate
    print(f"\n\n{name} table:")
    print(tb(rows, headers, tablefmt="grid"))

def create_database_and_tables():
    """Create a SQLite database and execute SQL scripts to create tables and insert data.
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
    - The 'schema.sql' file should contain the SQL commands to create the necessary tables,
    and the 'queries.sql' file should contain the SQL commands to insert data into those tables.
    - The script also fetches and displays the contents of the 'students', 'tests', and 'tests_sessions' tables.
    - It prints the names of all tables in the database at the end.
    """
    print("Hello from ems-db!")

    # Connect to the SQLite database (create if it doesn't exist)
    connection = sqlite3.connect("ems.db")

    # Create a cursor object
    cursor = connection.cursor()

    # Open and read the SQL file
    with open("schema.sql", "r") as sql_file:
        sql_schema_script = sql_file.read()

    # Open and read the SQL file
    with open("queries.sql", "r") as sql_file:
        sql_queries_script = sql_file.read()

    # Execute the SQL scripts for creating tables and inserting data
    cursor.executescript(sql_schema_script)
    cursor.executescript(sql_queries_script)
    
    # fetch some tables
    print("\n\nTables created :) ...")
    print("\n\nLet's view few tables: ...")
    
    cursor.execute("SELECT * FROM students")
    pretty_print_table(cursor, "Students")

    cursor.execute("SELECT * FROM tests")
    pretty_print_table(cursor, "Tests")
    
    cursor.execute("SELECT * FROM tests_sessions")
    pretty_print_table(cursor, "Tests Sessions")
    
    print("\n\nBye from ems-db! Further Explore Using `sqlite3 Shell` :) ...\n\n")
    
    # Query the sqlite_master table to get table names
    result = cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
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
