import sqlite3
from time import sleep

from psql.db import TEST_COMPLETION_TIME
import pytest

TEST_COMPLETION_TIME = 3


# Use an in-memory database for testing to avoid file conflicts
# and ensure a clean state for each test run.
# Or use a fixture to manage the database file lifecycle.
@pytest.fixture(scope="module")
def db_connection():
    # Setup: Create an in-memory database and apply schema + initial data
    connection = sqlite3.connect(":memory:")
    with open("schema.sql", "r") as sql_file:
        sql_schema_script = sql_file.read()
    with open("queries.sql", "r") as sql_file:
        sql_queries_script = sql_file.read()

    q1, q2 = sql_queries_script.split(r"$$$testbreak", maxsplit=1)

    cursor = connection.cursor()
    cursor.executescript(sql_schema_script)
    cursor.executescript(q1)
    sleep(TEST_COMPLETION_TIME)
    cursor.executescript(q2)
    connection.commit()

    yield connection

    # Teardown: Close the connection
    connection.close()


def test_state1_results():
    # This test assumes state1() was implicitly run by the fixture setup (q1 part)
    # It checks the state *before* q2 is applied by the fixture.
    # To test state *after* only state1, a separate fixture/setup is needed.
    # For simplicity, let's adjust the tests to check the final state after q1 and q2.
    # If testing intermediate state is crucial, more fixtures are required.

    # Re-executing q1 to check its specific results before q2 effects
    connection = sqlite3.connect(":memory:")
    cursor = connection.cursor()
    with open("schema.sql", "r") as sql_file:
        sql_schema_script = sql_file.read()
    with open("queries.sql", "r") as sql_file:
        sql_queries_script = sql_file.read()
    q1, _ = sql_queries_script.split(r"$$$testbreak", maxsplit=1)
    cursor.executescript(sql_schema_script)
    cursor.executescript(q1)
    connection.commit()

    cursor.execute(
        "SELECT id, test_session_id, question_id, answer, score FROM results ORDER BY id"
    )
    results = cursor.fetchall()
    # Based on the provided output for state after Part 1
    expected_results = [
        (1, 1, 1, 3, 1),
        (2, 1, 2, 5, 1),
        (3, 2, 1, 1, 0),
        (4, 2, 2, 5, 1),
    ]
    assert results == expected_results
    connection.close()


def test_final_tests_sessions_state(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("SELECT id, status FROM tests_sessions ORDER BY id")
    sessions = cursor.fetchall()
    # Based on the provided output after Part 2
    expected_sessions = [
        (1, "completed"),
        (2, "ended"),
    ]
    assert sessions == expected_sessions


def test_final_proctoring_sessions_state(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("SELECT id, status FROM proctoring_sessions ORDER BY id")
    sessions = cursor.fetchall()
    # Based on the provided output after Part 2
    expected_sessions = [
        (1, "completed"),
        (2, "completed"),
    ]
    assert sessions == expected_sessions


def test_final_events_state(db_connection):
    cursor = db_connection.cursor()
    # Check for the specific event added in Part 2
    cursor.execute(
        "SELECT proctoring_session_id, type, description FROM events WHERE type = 'suspicious-behavior'"
    )
    suspicious_event = cursor.fetchone()
    assert suspicious_event == (
        2,
        "suspicious-behavior",
        "not present in front of screen",
    )
    # Check total number of events if needed
    cursor.execute("SELECT COUNT(*) FROM events")
    event_count = cursor.fetchone()[0]
    assert event_count == 5  # 2 start, 2 end/complete, 1 suspicious


def test_final_reports_state(db_connection):
    cursor = db_connection.cursor()
    cursor.execute(
        "SELECT id, test_session_id, total_score, final_score, overall_feedback FROM reports ORDER BY id"
    )
    reports = cursor.fetchall()
    # Based on the provided output after Part 2
    expected_reports = [
        (1, 1, 2, 2, "great"),
        (2, 2, 2, 1, "need-improvement"),
    ]
    assert reports == expected_reports


def test_view_tests_history_john_doe(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("""
        SELECT student_id, test_title, total_score, scored, overall_feedback, duration_taken
        FROM tests_history
        WHERE student_id = (SELECT id FROM students WHERE first_name = 'John' AND last_name = 'Doe')
    """)
    history = cursor.fetchall()
    expected_history = [(1, "sql", 2, 2, "great", "00:00:03")]
    assert history == expected_history


def test_view_test_questions_option_search_demo(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("""
        SELECT question, option, is_correct
        FROM test_questions_option_search
        WHERE title = 'demo' ORDER BY option
     """)
    options = cursor.fetchall()
    expected_options = [
        ("TEXT is not dtype in sqlite?", "FALSE", 1),
        ("TEXT is not dtype in sqlite?", "TRUE", 0),
    ]
    # Sort results for consistent comparison if order isn't guaranteed by query
    assert sorted(options) == sorted(expected_options)


def test_view_suspicious_behaviour_search_ended(db_connection):
    cursor = db_connection.cursor()
    cursor.execute("""
        SELECT test_session_id, student_id, description
        FROM test_sessions_suspicious_behaviour_search
        WHERE test_session_status = 'ended'
    """)
    suspicious = cursor.fetchall()
    expected_suspicious = [(2, 2, "not present in front of screen")]
    assert suspicious == expected_suspicious
