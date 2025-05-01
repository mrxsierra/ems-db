-- Create/Reset database schema
DROP VIEW IF EXISTS "tests_history";
DROP VIEW IF EXISTS "test_questions_option_search";
DROP VIEW IF EXISTS "test_sessions_suspicious_behaviour_search";

-- Drop indexes
DROP INDEX IF EXISTS "idx_tests_sessions";
DROP INDEX IF EXISTS "idx_tests_sessions_status";
DROP INDEX IF EXISTS "idx_reports";
DROP INDEX IF EXISTS "idx_students";
DROP INDEX IF EXISTS "idx_questions_options";
DROP INDEX IF EXISTS "idx_questions_options_is_correct";
DROP INDEX IF EXISTS "idx_tests";
DROP INDEX IF EXISTS "idx_questions";
DROP INDEX IF EXISTS "idx_events";


-- Drop tables
DROP TABLE IF EXISTS "reports";
DROP TABLE IF EXISTS "results";
DROP TABLE IF EXISTS "events";
DROP TABLE IF EXISTS "proctoring_sessions";
DROP TABLE IF EXISTS "proctors";
DROP TABLE IF EXISTS "tests_sessions";
DROP TABLE IF EXISTS "questions_options";
DROP TABLE IF EXISTS "questions";
DROP TABLE IF EXISTS "tests";
DROP TABLE IF EXISTS "students";

-- CREATE TABLES

-- Represents students taking the test
CREATE TABLE "students" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "email" TEXT NOT NULL UNIQUE,
    PRIMARY KEY ("id")
);


-- Represents tests available in system
CREATE TABLE "tests" (
    "id" INTEGER,
    "title" TEXT NOT NULL UNIQUE,
    "description" TEXT NOT NULL,
    "duration" NUMERIC NOT NULL,
    "instructions" TEXT NOT NULL,
    "course" TEXT NOT NULL,
    PRIMARY KEY ("id")
);


-- Represents questions in tests
-- support multiple choice and true/false
CREATE TABLE "questions" (
    "id" INTEGER,
    "test_id" INTEGER,
    "question" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "topic" TEXT NOT NULL,
    "duration" NUMERIC NOT NULL,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("test_id") REFERENCES "tests" ("id")
);


-- Represents options for multiple-option questions
CREATE TABLE "questions_options" (
    "id" INTEGER,
    "question_id" INTEGER,
    "option" TEXT NOT NULL,
    "is_correct" INTEGER NOT NULL CHECK ("is_correct" IN (0, 1)), --bool
    PRIMARY KEY ("id"),
    FOREIGN KEY ("question_id") REFERENCES "questions" ("id")
);


-- Represents sessions in which users take tests
CREATE TABLE "tests_sessions" (
    "id" INTEGER,
    "test_id" INTEGER,
    "student_id" INTEGER,
    "start" NUMERIC NOT NULL DEFAULT (DATETIME('now', 'localtime')),
    "end" NUMERIC, -- trigger added.
    "duration_taken" NUMERIC, -- trigger added
    "status" TEXT NOT NULL DEFAULT 'in-progress' CHECK (
        "status" IN ('in-progress', 'ended', 'completed')
    ),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("test_id") REFERENCES "tests" ("id"),
    FOREIGN KEY ("student_id") REFERENCES "students" ("id")
);


-- Represents individuals who supervises test sessions
CREATE TABLE "proctors" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "email" TEXT NOT NULL UNIQUE,
    PRIMARY KEY ("id")
);


-- Represents sessions in which proctors supervise test sessions
CREATE TABLE "proctoring_sessions" (
    "id" INTEGER,
    "proctor_id" INTEGER,
    "test_session_id" INTEGER,
    "start" NUMERIC NOT NULL DEFAULT (DATETIME('now', 'localtime')),
    "end" NUMERIC, -- trigger added
    "status" TEXT NOT NULL DEFAULT 'active' CHECK (
        "status" IN ('active', 'completed')
    ),
    PRIMARY KEY ("id"),
    FOREIGN KEY ("test_session_id") REFERENCES "tests_sessions" ("id"),
    FOREIGN KEY ("proctor_id") REFERENCES "proctors" ("id")
);


-- Represents events occurring during proctoring sessions
-- trigger added for some new auto updates and entries
CREATE TABLE "events" (
    "id" INTEGER,
    "proctoring_session_id" INTEGER,
    "type" TEXT NOT NULL CHECK (
        "type" IN (
            'started-test',
            'completed-test',
            'ended-test',
            'suspicious-behavior'
        )
    ),
    "timestamp" NUMERIC NOT NULL DEFAULT (DATETIME('now', 'localtime')),
    "description" TEXT DEFAULT 'OK',
    PRIMARY KEY ("id"),
    FOREIGN KEY ("proctoring_session_id") REFERENCES "proctoring_sessions" (
        "id"
    )
);


-- Represents the results of test sessions
-- trigger added for some new auto updates adn entries
CREATE TABLE "results" (
    "id" INTEGER,
    "test_session_id" INTEGER,
    "question_id" INTEGER,
    "answer" INTEGER NOT NULL,
    "score" INTEGER NOT NULL DEFAULT 0 CHECK ("score" IN (0, 1)),
    "feedback" TEXT,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("test_session_id") REFERENCES "tests_sessions" ("id"),
    FOREIGN KEY ("question_id") REFERENCES "questions" ("id"),
    FOREIGN KEY ("answer") REFERENCES "questions_options" ("id")
);


-- Represents reports generated for test sessions
CREATE TABLE "reports" (
    "id" INTEGER,
    "test_session_id" INTEGER,
    "total_score" INTEGER,
    "final_score" INTEGER,  -- trigger added.
    "overall_feedback" TEXT,
    PRIMARY KEY ("id"),
    FOREIGN KEY ("test_session_id") REFERENCES "tests_sessions" ("id")
);


-- CREATE TRIGGERS: to UPDATE and INSERT values

-- Create a trigger to set the end time based on the tests duration
CREATE TRIGGER "set_end_for_test_session" AFTER INSERT ON "tests_sessions"
BEGIN
UPDATE "tests_sessions"
SET
    "end" = DATETIME(new.start, '+' || (
            SELECT TIME(duration)
            FROM "tests" AS t
            WHERE t."id" = new."test_id"
        ))
WHERE "id" = new.id;
END;


-- Create a trigger to add events for when test session started
-- assumes: as soon as proctor starts proctoring session,
-- We add some events(student logs) as proctor obeserve in session)
CREATE TRIGGER "add_events_starts" AFTER INSERT ON "proctoring_sessions"
BEGIN
INSERT INTO "events" ("proctoring_session_id", "type")
VALUES (new.id, 'started-test');
END;


-- Create a trigger to set score for answer of questions
CREATE TRIGGER "set_score_of_result" AFTER INSERT ON "results"
BEGIN
UPDATE "results"
SET
    "score"
    = (
        SELECT "questions_options"."is_correct" FROM "questions_options"
        WHERE "questions_options"."id" = new.answer
    ),
    "feedback"
    = CASE
        WHEN
            (
                SELECT "questions_options"."is_correct" FROM "questions_options"
                WHERE "questions_options"."id" = new.answer
            ) = 0
            THEN 'need-improvement'
        ELSE 'great'
    END
WHERE "id" = new.id;
END;


-- create a trigger to update tests sessions, events,
-- proctoring session and reports on tests session status update
CREATE TRIGGER "update_status_end_final_score_all" AFTER UPDATE
ON "tests_sessions"
WHEN new.status IN ('ended', 'completed')
AND old.status NOT IN ('ended', 'completed')
BEGIN
-- Create a trigger to set the duration taken based on the tests duration
UPDATE "tests_sessions"
SET
    "duration_taken"
    = CASE
        WHEN STRFTIME('%s', 'now', 'localtime') < STRFTIME('%s', new.start) THEN '00:00:00' -- Or handle error/impossibility
        ELSE STRFTIME('%H:%M:%S', DATETIME(STRFTIME('%s', 'now', 'localtime') - STRFTIME('%s', new.start), 'unixepoch'))
    END
WHERE "id" = new.id;

-- Add event for test session
INSERT INTO "events" ("proctoring_session_id", "type")
VALUES
(
    new.id,
    CASE
        WHEN new.status = 'ended' THEN 'ended-test'
        ELSE 'completed-test'
    END
);

-- Update end time and status for proctoring session
UPDATE "proctoring_sessions"
SET "end" = (DATETIME('now', 'localtime')), "status" = 'completed'
WHERE "id" = new.id;

--  add reports for test session
INSERT INTO "reports" (
    "test_session_id", "total_score", "final_score", "overall_feedback"
)
VALUES (
    new.id,
    (
        SELECT COUNT(*) FROM "results"
        WHERE "results"."test_session_id" = new.id
    ),
    (
        SELECT SUM("results"."score") FROM "results"
        WHERE "results"."test_session_id" = new.id
    ),
    (
        SELECT MAX("results"."feedback") FROM "results"
        WHERE "results"."test_session_id" = new.id
    )
);
END;


-- CREATE VIEWS: to simplify quering

-- VIEW all students test performance history in test they took
CREATE VIEW "tests_history" AS
SELECT
    ts."student_id",
    t."title" AS "test_title",
    r."total_score",
    r."final_score" AS "scored",
    r."overall_feedback",
    ts."duration_taken"
FROM "reports" AS r
INNER JOIN "tests_sessions" AS ts ON r."test_session_id" = ts."id"
INNER JOIN "tests" AS t ON ts."test_id" = t."id";


-- VIEW all tests and their questions as well as options
CREATE VIEW "test_questions_option_search" AS
SELECT
    t."title",
    t."description",
    t."duration" AS "test_duration",
    t."course",
    q."question",
    q."type",
    q."topic",
    q."duration" AS "time_to_solve",
    qo."option",
    qo."is_correct"
FROM "tests" AS t
INNER JOIN "questions" AS q ON t."id" = q."test_id"
INNER JOIN "questions_options" AS qo ON q."id" = qo."question_id";

-- VIEW tests session of suspicious behaviour
CREATE VIEW "test_sessions_suspicious_behaviour_search" AS
SELECT
    ps."test_session_id",
    ts."student_id",
    ts."duration_taken",
    ts."status" AS "test_session_status",
    ps."proctor_id",
    e."proctoring_session_id",
    e."type",
    e."timestamp",
    e."description"
FROM "tests_sessions" AS ts
INNER JOIN "proctoring_sessions" AS ps ON ts."id" = ps."test_session_id"
INNER JOIN "events" AS e ON ps."id" = e."proctoring_session_id"
WHERE e."type" = 'suspicious-behavior';


-- CREATE INDEXES: to speed common searches
CREATE INDEX "idx_tests_sessions" ON "tests_sessions" (
    "student_id", "test_id", "id"
);
CREATE INDEX "idx_tests_sessions_status" ON "tests_sessions" ("status");
CREATE INDEX "idx_reports" ON "reports" ("test_session_id", "id");
CREATE INDEX "idx_students" ON "students" ("first_name", "last_name", "email");
CREATE INDEX "idx_questions_options" ON "questions_options" (
    "question_id", "is_correct"
);
CREATE INDEX "idx_questions_options_is_correct" ON "questions_options" (
    "is_correct"
)
WHERE "is_correct" = 1;
CREATE INDEX "idx_tests" ON "tests" ("title");
CREATE INDEX "idx_questions" ON "questions" ("test_id", "id");
CREATE INDEX "idx_events" ON "events" ("type");
