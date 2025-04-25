-- INSERT/DELETE data from tables (reset-tables)
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

-- reset auroincrement
ALTER TABLE reports AUTO_INCREMENT = 1;
ALTER TABLE results AUTO_INCREMENT = 1;
ALTER TABLE events AUTO_INCREMENT = 1;
ALTER TABLE proctoring_sessions AUTO_INCREMENT = 1;
ALTER TABLE proctors AUTO_INCREMENT = 1;
ALTER TABLE tests_sessions AUTO_INCREMENT = 1;
ALTER TABLE questions_options AUTO_INCREMENT = 1;
ALTER TABLE questions AUTO_INCREMENT = 1;
ALTER TABLE tests AUTO_INCREMENT = 1;
ALTER TABLE students AUTO_INCREMENT = 1;

-- INSERT SECTION
-- Add new students
INSERT INTO students (first_name, last_name, password, email)
VALUES 
	('John', 'Doe', 'password123', 'john.doe@example.com'),
	('Jane', 'Smith', 'testpass', 'jane.smith@example.com');

-- Add new tests
INSERT INTO tests (title, description, duration, instructions, course)
VALUES 
	('sql', 'structured query language test', '00:30:00', 'choose correct option for questions', 'sql'),
	('demo', 'some test', '00:30:00', 'some instruction', 'random');

-- Add new questions for tests
INSERT INTO questions (test_id, question, type, topic, duration)
VALUES 
	(1, 'Which is not dtype for sqlite?', 'multiple-choice', 'dtype', '00:03:00'),
	(1, 'TEXT is dtype in sqlite?', 'true/false', 'dtype', '00:03:00'),
	(2, 'TEXT is not dtype in sqlite?', 'true/false', 'dtype', '00:03:00');

-- Add new multiple options for questions
INSERT INTO questions_options (question_id, `option`, is_correct)
VALUES 
	(1, 'TEXT', 0),
	(1, 'INTEGER', 0),
	(1, 'STR', 1),
	(1, 'NUMERIC', 0),
	(2, 'TRUE', 1),
	(2, 'FALSE', 0),
	(3, 'TRUE', 0),
	(3, 'FALSE', 1);

-- Add new test sessions for test-taking students
INSERT INTO tests_sessions (test_id, student_id)
VALUES 
	(1, 1),
	(1, 2);

-- Add new proctors
INSERT INTO proctors (first_name, last_name, password, email)
VALUES 
	('Carter', 'Zenke', 'password123', 'carter.zenke@example.com'),
	('David', 'Melone', 'testpass', 'david.melone@example.com');

-- Add new proctoring sessions for proctors
INSERT INTO proctoring_sessions (proctor_id, test_session_id)
VALUES 
	(1, 1),
	(1, 2);

-- Add new results of test_session questions based on user answers
INSERT INTO results (test_session_id, question_id, answer)
VALUES 
	(1, 1, 3),
	(1, 2, 5),
	(2, 1, 1),
	(2, 2, 5);

-- SELECT SECTION
-- Retrieve data from all tables
SELECT * FROM students;
SELECT * FROM tests;
SELECT * FROM questions;
SELECT * FROM questions_options;
SELECT * FROM tests_sessions;
SELECT * FROM proctors;
SELECT * FROM proctoring_sessions;
SELECT * FROM events;
SELECT * FROM results;
SELECT * FROM reports;

-- UPDATE/SELECT SECTION
-- Update test session status
UPDATE tests_sessions
SET status = 'completed'
WHERE id = 1;

-- Simulate a delay of 5 seconds
SELECT SLEEP(5);

-- Update test session status
UPDATE tests_sessions
SET status = 'ended'
WHERE id = 2;

-- Recheck updates
SELECT * FROM tests_sessions;
SELECT * FROM proctoring_sessions;

-- Log suspicious behavior
INSERT INTO events (proctoring_session_id, type, description)
VALUES (2, 'suspicious-behavior', 'not present in front of screen');

-- Recheck events
SELECT * FROM events;
SELECT * FROM results;
SELECT * FROM reports;

-- QUERIES of Interest
-- Find all submissions given student first and last name
SELECT * 
FROM tests_history
WHERE student_id = (
	SELECT id
	FROM students
	WHERE first_name = 'John'
	  AND last_name = 'Doe'
);

-- Find all submissions given student email
SELECT * 
FROM tests_history
WHERE student_id = (
	SELECT id
	FROM students
	WHERE email = 'john.doe@example.com'
);

-- Find all test questions and options given title
SELECT * 
FROM test_questions_option_search
WHERE title = 'demo';

-- Find all test questions and options where is_correct = 1
SELECT * 
FROM test_questions_option_search
WHERE is_correct = 1;

-- Find all test sessions with suspicious behavior
SELECT * 
FROM test_sessions_suspicious_behaviour_search
WHERE test_session_status = 'ended';

-- Check for errors and warnings
SHOW ERRORS;
SHOW WARNINGS;
