import os
from time import sleep

import mysql.connector as mysql
import pytest

# .env file variables
MYSQL_DATABASE = os.environ.get("MYSQL_DATABASE", default="ems")
MYSQL_HOST = os.environ.get("MYSQL_HOST", default="db")
MYSQL_USER = os.environ.get("MYSQL_USER", default="root")
MYSQL_PORT = int(os.environ.get("MYSQL_PORT", default=3306))  # Ensure it's an integer
MYSQL_PASSWORD = os.environ.get("MYSQL_PASSWORD")
RAISE_ON_WARNINGS = bool(os.environ.get("RAISE_ON_WARNINGS", default=True))

conn_config = {
    "user": MYSQL_USER,
    "password": MYSQL_PASSWORD,
    "host": MYSQL_HOST,
    "port": MYSQL_PORT,
    "database": MYSQL_DATABASE,
}


TEST_COMPLETION_TIME = 3


def execut_and_commit(cnx: mysql.MySQLConnection, queries: str, bufferd: bool = False):
    cursor = cnx.cursor(buffered=bufferd)
    try:
        for query in queries.strip().split(";"):
            if query.strip():  # Ensure query is not empty
                cursor.execute(query)
                try:
                    cursor.fetchall()
                except mysql.ProgrammingError:
                    pass
    finally:
        cursor.close()
        cnx.commit()


def load_sql_queries(filepath: str):
    """Load and split SQL queries using custom separator."""
    with open(filepath, "r", encoding="utf-8") as f:
        sql_script = f.read()
    q1, q2 = sql_script.split("$$$testbreak", maxsplit=1)
    q2 = q2.split("$$$sleeptestbreak", maxsplit=1)[1]
    return q1, q2


@pytest.fixture(scope="module")
def db_connection():
    """Database setup and teardown for tests."""
    connection = mysql.connect(**conn_config)
    q1, q2 = load_sql_queries("queries.sql")

    execut_and_commit(connection, q1)
    sleep(TEST_COMPLETION_TIME)  # simulate async operation/wait
    execut_and_commit(connection, q2)

    yield connection

    connection.close()


def fetch_results(connection, query: str, params=None):
    """Helper to execute query and fetch results."""
    cursor = None
    try:
        cursor = connection.cursor()
        cursor.execute(query, params or ())
        return cursor.fetchall()
    except mysql.Error as err:
        print(f"Error: {err}")
        return None
    finally:
        if cursor:
            cursor.close()


def test_state1_results():
    """Test initial state after Part 1 of setup."""
    connection = mysql.connect(**conn_config)
    q1, _ = load_sql_queries("queries.sql")

    execut_and_commit(connection, q1)

    results = fetch_results(
        connection,
        """
        SELECT id, test_session_id, question_id, answer, score
        FROM results
        ORDER BY id
    """,
    )

    expected_results = [
        (1, 1, 1, 3, 1),
        (2, 1, 2, 5, 1),
        (3, 2, 1, 1, 0),
        (4, 2, 2, 5, 1),
    ]

    assert results == expected_results
    connection.close()


def test_final_tests_sessions_state(db_connection):
    sessions = fetch_results(
        db_connection,
        """
        SELECT id, status
        FROM tests_sessions
        ORDER BY id
    """,
    )

    expected_sessions = [
        (1, "completed"),
        (2, "ended"),
    ]

    assert sessions == expected_sessions


def test_final_proctoring_sessions_state(db_connection):
    sessions = fetch_results(
        db_connection,
        """
        SELECT id, status
        FROM proctoring_sessions
        ORDER BY id
    """,
    )

    expected_sessions = [
        (1, "completed"),
        (2, "completed"),
    ]

    assert sessions == expected_sessions


def test_final_events_state(db_connection):
    suspicious_event = fetch_results(
        db_connection,
        """
        SELECT proctoring_session_id, type, description
        FROM events
        WHERE type = 'suspicious-behavior'
    """,
    )[0]

    assert suspicious_event == (
        2,
        "suspicious-behavior",
        "not present in front of screen",
    )

    event_count = fetch_results(db_connection, "SELECT COUNT(*) FROM events")[0][0]
    assert event_count == 5


def test_final_reports_state(db_connection):
    reports = fetch_results(
        db_connection,
        """
        SELECT id, test_session_id, total_score, final_score, overall_feedback
        FROM reports
        ORDER BY id
    """,
    )

    expected_reports = [
        (1, 1, 2, 2, "great"),
        (2, 2, 2, 1, "need-improvement"),
    ]

    assert reports == expected_reports


def test_view_tests_history_john_doe(db_connection):
    history = fetch_results(
        db_connection,
        """
        SELECT student_id, test_title, total_score, scored, overall_feedback,
               SEC_TO_TIME(duration_taken) AS duration_taken
        FROM tests_history
        WHERE student_id = (
            SELECT id
            FROM students
            WHERE first_name = "John"
              AND last_name = "Doe"
        )
    """,
    )

    def format_row(row):
        *rest, duration = row
        if hasattr(duration, "total_seconds"):
            seconds = int(duration.total_seconds())
            h = seconds // 3600
            m = (seconds % 3600) // 60
            s = seconds % 60
            duration_str = f"{h:02}:{m:02}:{s:02}"
        else:
            duration_str = duration
        return (*rest, duration_str)

    formatted_history = [format_row(row) for row in history]

    expected_history = [(1, "sql", 2, 2, "great", "00:00:03")]

    assert formatted_history == expected_history


def test_view_test_questions_option_search_demo(db_connection):
    options = fetch_results(
        db_connection,
        """
        SELECT question, `option`, is_correct
        FROM test_questions_option_search
        WHERE title = "demo"
        ORDER BY `option`
    """,
    )

    expected_options = [
        ("TEXT is not dtype in sqlite?", "FALSE", 1),
        ("TEXT is not dtype in sqlite?", "TRUE", 0),
    ]

    assert sorted(options) == sorted(expected_options)


def test_view_suspicious_behaviour_search_ended(db_connection):
    suspicious = fetch_results(
        db_connection,
        """
        SELECT test_session_id, student_id, description
        FROM test_sessions_suspicious_behaviour_search
        WHERE test_session_status = 'ended'
    """,
    )

    expected_suspicious = [(2, 2, "not present in front of screen")]

    assert suspicious == expected_suspicious
