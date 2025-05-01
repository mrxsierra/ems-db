import os
from time import sleep

import psycopg as psql
import pytest

# .env file variables
POSTGRES_DATABASE = os.environ.get("POSTGRES_DATABASE", default="ems")
POSTGRES_HOST = os.environ.get("POSTGRES_HOST", default="db")
POSTGRES_USER = os.environ.get("POSTGRES_USER", default="postgres")
POSTGRES_PORT = os.environ.get("POSTGRES_PORT", default=5432)
POSTGRES_PASSWORD = os.environ.get("POSTGRES_PASSWORD")

# Postgres database configuration
conn_config = {
    "user": POSTGRES_USER,
    "password": POSTGRES_PASSWORD,
    "host": POSTGRES_HOST,
    "port": POSTGRES_PORT,
    "dbname": POSTGRES_DATABASE,
}

TEST_COMPLETION_TIME = 3


def run_create_schema(connection) -> None:
    """Create schema using SQL executed directly via psycopg, supports large scripts."""
    with open("schema.sql", "r") as f:
        sql_script = f.read()

    connection.autocommit = True
    with connection.cursor() as cur:
        cur.execute(sql_script)


def load_sql_queries(filepath: str):
    """Load and split SQL queries using custom separator."""
    with open(filepath, "r") as f:
        sql_script = f.read()
    return sql_script.split(r"$$$testbreak", maxsplit=1)


@pytest.fixture(scope="module")
def db_connection():
    """Database setup and teardown for tests."""
    connection = psql.connect(**conn_config)

    # Setup schema and initial data
    run_create_schema(connection)
    q1, q2 = load_sql_queries("queries.sql")

    with connection.cursor() as cursor:
        cursor.execute(q1)
        connection.commit()

    sleep(TEST_COMPLETION_TIME)  # simulate async operation/wait

    with connection.cursor() as cursor:
        cursor.execute(q2)
        connection.commit()

    yield connection

    # Teardown
    connection.close()


def fetch_results(connection, query: str, params=None):
    """Helper to execute query and fetch results."""
    with connection.cursor() as cursor:
        cursor.execute(query, params)
        return cursor.fetchall()


def test_state1_results():
    """Test initial state after Part 1 of setup."""
    connection = psql.connect(**conn_config)
    run_create_schema(connection)
    q1, _ = load_sql_queries("queries.sql")

    with connection.cursor() as cursor:
        cursor.execute(q1)
        connection.commit()

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
    assert event_count == 5  # 2 start, 2 end/complete, 1 suspicious


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
               TO_CHAR((duration_taken || ' seconds')::interval, 'HH24:MI:SS') AS duration_taken
        FROM tests_history
        WHERE student_id = (SELECT id FROM students WHERE first_name = 'John' AND last_name = 'Doe')
    """,
    )

    expected_history = [(1, "sql", 2, 2, "great", "00:00:03")]

    assert history == expected_history


def test_view_test_questions_option_search_demo(db_connection):
    options = fetch_results(
        db_connection,
        """
        SELECT question, option, is_correct
        FROM test_questions_option_search
        WHERE title = 'demo'
        ORDER BY option
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
