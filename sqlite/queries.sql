-- Part 1 Initial Insertion
-- INSERT/DELETE data from tables(reset-tables)
DELETE FROM reports;

DELETE FROM results;

DELETE FROM events;

DELETE FROM proctoring_sessions;

DELETE FROM proctors;

DELETE FROM tests_sessions;

DELETE FROM questions_options;

DELETE FROM questions;

DELETE FROM tests;

DELETE FROM students;

-- INSERT SECTION
-- Add a new students
INSERT INTO students (first_name, last_name, password, email)
VALUES ('John', 'Doe', 'password123', 'john.doe@example.com'),
('Jane', 'Smith', 'testpass', 'jane.smith@example.com');

-- Add a new tests
INSERT INTO tests (
    title, description, duration, instructions, course
)
VALUES (
    'sql',
    'stuctured query language test',
    '00:30',
    'choose correct option for questions',
    'sql'
),
('demo', 'some test', '00:30', 'some instruction', 'random');

-- Add a new questioins for tests
INSERT INTO questions (test_id, question, type, topic, duration)
VALUES (
    1, 'Which is not dtype for sqlite?', 'multiple-choice', 'dtype', '00:03'
),
(1, 'TEXT is dtype in sqlite?', 'true/false', 'dtype', '00:03'),
(2, 'TEXT is not dtype in sqlite?', 'true/false', 'dtype', '00:03');

-- Add a new multiple option for questions
INSERT INTO questions_options (question_id, option, is_correct) -- noqa
VALUES (1, 'TEXT', 0),
(1, 'INTEGER', 0),
(1, 'STR', 1),
(1, 'NUMERIC', 0),
(2, 'TRUE', 1),
(2, 'FALSE', 0),
(3, 'TRUE', 0),
(3, 'FALSE', 1);

-- Add a new test sessions for test taking student
INSERT INTO tests_sessions (test_id, student_id)
VALUES (1, 1),
(1, 2);

-- Add a new proctors
INSERT INTO proctors (first_name, last_name, password, email)
VALUES ('Carter', 'Zenke', 'password123', 'carter.zenke@example.com'),
('David', 'Melone', 'testpass', 'david.melone@example.com');

-- Add a new proctoring sessions for proctor
-- when start proctoring test sessions (assuming its manual)
INSERT INTO proctoring_sessions (proctor_id, test_session_id)
VALUES (1, 1),
(1, 2);

-- Add a new results of test_session questions based on user answer
INSERT INTO results (test_session_id, question_id, answer)
VALUES (1, 1, 3),
(1, 2, 5),
(2, 1, 1),
(2, 2, 5);

-- DB State after Part 1 Execution
-- some SELECT queries on all tables
SELECT *
FROM students;

SELECT *
FROM tests;

SELECT *
FROM questions;

SELECT *
FROM questions_options;

SELECT *
FROM tests_sessions;

SELECT *
FROM proctors;

SELECT *
FROM proctoring_sessions;

SELECT *
FROM events;

SELECT *
FROM results;

SELECT *
FROM reports;

-- $$$testbreak

-- UPDATE/SELECT SECTION part 2
-- some updates
UPDATE tests_sessions
SET status = 'completed'
WHERE id = 1;

UPDATE tests_sessions
SET status = 'ended'
WHERE id = 2;

-- Recheck test session update State
SELECT *
FROM tests_sessions;

SELECT *
FROM proctoring_sessions;

-- some update of suspicious behaviour
INSERT INTO events (proctoring_session_id, type, description)
VALUES (2, 'suspicious-behavior', 'not present in front of screen');

-- Rechack events, results and reports state after suspicious beahaviour
SELECT *
FROM events;

SELECT *
FROM results;

SELECT *
FROM reports;

-- QUERIES of Interest [check db state using views]
-- Find all submissions given student first and last name
-- EXPLAIN QUERY PLAN
SELECT *
FROM tests_history
WHERE student_id = (
    SELECT id
    FROM students
    WHERE
        first_name = 'John'
        AND last_name = 'Doe'
);

-- Find all submissions given student email
-- EXPLAIN QUERY PLAN
SELECT *
FROM tests_history
WHERE student_id = (
    SELECT id
    FROM students
    WHERE email = 'john.doe@example.com'
);

-- FIND all tests question and option given title
-- EXPLAIN QUERY PLAN
SELECT *
FROM test_questions_option_search
WHERE title = 'demo';

-- FIND all tests question and option given is_correct
-- EXPLAIN QUERY PLAN
SELECT *
FROM test_questions_option_search
WHERE is_correct = 1;

-- Find all test sessions of suspicious beahviour
-- EXPLAIN QUERY PLAN
SELECT *
FROM test_sessions_suspicious_behaviour_search
WHERE test_session_status = 'ended';
