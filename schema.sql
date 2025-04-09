-- Create/Reset database schema
DROP VIEW IF EXISTS "tests_history";
DROP VIEW IF EXISTS "test_questions_option_search";
DROP VIEW IF EXISTS "test_sessions_suspicious_behaviour_search";


DROP INDEX IF EXISTS "idx_tests_sessions";
DROP INDEX IF EXISTS "idx_tests_sessions_status";
DROP INDEX IF EXISTS "idx_reports";
DROP INDEX IF EXISTS "idx_students";
DROP INDEX IF EXISTS "idx_questions_options";
DROP INDEX IF EXISTS "idx_questions_options_is_correct";
DROP INDEX IF EXISTS "idx_tests";
DROP INDEX IF EXISTS "idx_questions";
DROP INDEX IF EXISTS "idx_events";


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
    PRIMARY KEY("id")
);


-- Represents tests available in system
CREATE TABLE "tests" (
    "id" INTEGER,
    "title" TEXT NOT NULL UNIQUE,
    "description" TEXT NOT NULL,
    "duration" NUMERIC NOT NULL,
    "instructions" TEXT NOT NULL,
    "course" TEXT NOT NULL,
    PRIMARY KEY("id")
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
    PRIMARY KEY("id"),
    FOREIGN KEY("test_id") REFERENCES "tests"("id")
);


-- Represents options for multiple-option questions
CREATE TABLE "questions_options" (
    "id" INTEGER,
    "question_id" INTEGER,
    "option" TEXT NOT NULL,
    "is_correct" INTEGER NOT NULL CHECK("is_correct" IN (0,1)), --bool
    PRIMARY KEY("id"),
    FOREIGN KEY("question_id") REFERENCES "questions"("id")
);


-- Represents sessions in which users take tests
CREATE TABLE "tests_sessions" (
    "id" INTEGER,
    "test_id" INTEGER,
    "student_id" INTEGER,
    "start" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "end" NUMERIC, -- trigger added.
    "duration_taken" NUMERIC, -- trigger added
    "status" TEXT NOT NULL DEFAULT 'in-progress' CHECK("status" IN ('in-progress', 'ended','completed')),
    PRIMARY KEY("id"),
    FOREIGN KEY("test_id") REFERENCES "tests"("id"),
    FOREIGN KEY("student_id") REFERENCES "students"("id")
);


-- Represents individuals who supervises test sessions
CREATE TABLE "proctors" (
    "id" INTEGER,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "email" TEXT NOT NULL UNIQUE,
    PRIMARY KEY("id")
);


-- Represents sessions in which proctors supervise test sessions
CREATE TABLE "proctoring_sessions" (
    "id" INTEGER,
    "proctor_id" INTEGER,
    "test_session_id" INTEGER,
    "start" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "end" NUMERIC, -- trigger added
    "status" TEXT NOT NULL DEFAULT 'active' CHECK("status" IN ('active', 'completed')),
    PRIMARY KEY("id"),
    FOREIGN KEY("test_session_id") REFERENCES "tests_sessions"("id"),
    FOREIGN KEY("proctor_id") REFERENCES "proctors"("id")
);


-- Represents events occurring during proctoring sessions
-- trigger added for some new auto updates and entries
CREATE TABLE "events" (
    "id" INTEGER,
    "proctoring_session_id" INTEGER,
    "type" TEXT NOT NULL CHECK("type" IN ('started-test', 'completed-test', 'ended-test', 'suspicious-behavior')),
    "timestamp" NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "description" TEXT DEFAULT 'OK',
    PRIMARY KEY("id"),
    FOREIGN KEY("proctoring_session_id") REFERENCES "proctoring_sessions"("id")
);


-- Represents the results of test sessions
-- trigger added for some new auto updates adn entries
CREATE TABLE "results" (
    "id" INTEGER,
    "test_session_id" INTEGER,
    "question_id" INTEGER,
    "answer" INTEGER NOT NULL,
    "score" INTEGER NOT NULL DEFAULT 0 CHECK("score" IN (0,1)),
    "feedback" TEXT,
    PRIMARY KEY("id"),
    FOREIGN KEY("test_session_id") REFERENCES "tests_sessions"("id"),
    FOREIGN KEY("question_id") REFERENCES "questions"("id"),
    FOREIGN KEY("answer") REFERENCES "questions_options"("id")
);


-- Represents reports generated for test sessions
CREATE TABLE "reports" (
    "id" INTEGER,
    "test_session_id" INTEGER,
    "total_score" INTEGER,
    "final_score" INTEGER,  -- trigger added.
    "overall_feedback" TEXT,
    PRIMARY KEY("id"),
    FOREIGN KEY("test_session_id") REFERENCES "tests_sessions"("id")
);


-- CREATE TRIGGERS: to UPDATE and INSERT values

-- Create a trigger to set the end time based on the tests duration
CREATE TRIGGER "set_end_for_test_session" AFTER INSERT ON "tests_sessions"
BEGIN
    UPDATE "tests_sessions"
    SET "end" = strftime('%Y-%m-%d %H:%M:%S', 'now', '+' || (SELECT "duration" FROM "tests" WHERE "id" = 'NEW'.'id'))
    WHERE "id" = NEW.id;
END;


-- Create a trigger to add events for when test session started
-- assumes: as soon as proctor starts proctoring session,
         -- We add some events(student logs) as proctor obeserve in session)
CREATE TRIGGER "add_events_starts" AFTER INSERT ON "proctoring_sessions"
BEGIN
    INSERT INTO "events" ("proctoring_session_id", "type")
    VALUES (NEW.id, 'started-test');
END;


-- Create a trigger to set score for answer of questions
CREATE TRIGGER "set_score_of_result" AFTER INSERT ON "results"
BEGIN
    UPDATE "results"
    SET "score" = (SELECT "is_correct" FROM "questions_options" WHERE "id" = NEW.answer),
        "feedback" =
        CASE
            WHEN (SELECT "is_correct" FROM "questions_options" WHERE "id" = NEW.answer) = 0 THEN 'need-improvement'
            ELSE 'great'
        END
    WHERE "id" = NEW.id;
END;


-- create a trigger to update tests sessions, events, proctoring session and reports on tests session status update
CREATE TRIGGER "update_status_end_final_score_all" AFTER UPDATE ON "tests_sessions"
WHEN NEW.status IN ('ended', 'completed') AND OLD.status NOT IN ('ended', 'completed')
BEGIN
    -- Create a trigger to set the duration taken based on the tests duration
    UPDATE "tests_sessions"
    SET "duration_taken" =
        CASE
            WHEN strftime('%s', NEW.start) > strftime('%s', 'now') THEN '00:00'
            ELSE strftime('%H:%M', 'now', '-' || NEW.start)
        END
    WHERE "id" = NEW.id;

    -- Add event for test session
    INSERT INTO "events" ("proctoring_session_id", "type")
    VALUES
        (NEW.id,
         CASE
            WHEN NEW.status = 'ended' THEN 'ended-test'
            ELSE 'completed-test'
         END);

    -- Update end time and status for proctoring session
    UPDATE "proctoring_sessions"
    SET "end" = CURRENT_TIMESTAMP, "status" = 'completed'
    WHERE "id" = NEW.id;

    --  add reports for test session
    INSERT INTO "reports" ("test_session_id", "total_score", "final_score", "overall_feedback")
    VALUES (
        NEW.id,
        (SELECT COUNT(*) FROM "results" WHERE "test_session_id" = NEW.id),
        (SELECT SUM("score") FROM "results" WHERE "test_session_id" = NEW.id),
        (SELECT MAX("feedback") FROM "results" WHERE "test_session_id" = NEW.id)
    );
END;


-- CREATE VIEWS: to simplify quering

-- VIEW all students test performance history in test they took
CREATE VIEW "tests_history" AS
SELECT
    "TS"."student_id",
    "T"."title" AS "test_title",
    "R"."total_score",
    "R"."final_score" AS "scored",
    "R"."overall_feedback",
    "TS"."duration_taken"
FROM "reports" AS "R"
JOIN "tests_sessions" AS "TS" ON "R"."test_session_id" = "TS"."id"
JOIN "tests" AS "T" ON "TS"."test_id" = "T"."id";


-- VIEW all tests and their questions as well as options
CREATE VIEW "test_questions_option_search" AS
SELECT
    "T"."title",
    "T"."description",
    "T"."duration" "test_duration",
    "T"."course",
    "Q"."question",
    "Q"."type",
    "Q"."topic",
    "Q"."duration" "time_to_solve",
    "QO"."option",
    "QO"."is_correct"
FROM "tests" "T"
JOIN "questions" "Q" ON "Q"."test_id" = "T"."id"
JOIN "questions_options" "QO" ON "QO"."question_id" = "Q"."id";

-- VIEW tests session of suspicious behaviour
CREATE VIEW "test_sessions_suspicious_behaviour_search" AS
SELECT
    "PS"."test_session_id",
    "TS"."student_id",
    "TS"."duration_taken",
    "TS"."status" "test_session_status",
    "PS"."proctor_id",
    "E"."proctoring_session_id",
    "E"."type",
    "E"."timestamp",
    "E"."description"
FROM "tests_sessions" "TS"
JOIN "proctoring_sessions" "PS" ON "TS"."id" = "PS"."test_session_id"
JOIN "events" "E" ON "PS"."id" = "E"."proctoring_session_id"
WHERE "E"."type" = 'suspicious-behavior';


-- CREATE INDEXES: to speed common searches
CREATE INDEX "idx_tests_sessions" ON "tests_sessions" ("student_id", "test_id", "id");
CREATE INDEX "idx_tests_sessions_status" ON "tests_sessions" ("status");
CREATE INDEX "idx_reports" ON "reports" ("test_session_id", "id");
CREATE INDEX "idx_students" ON "students" ("first_name", "last_name", "email");
CREATE INDEX "idx_questions_options" ON "questions_options" ("question_id", "is_correct");
CREATE INDEX "idx_questions_options_is_correct" ON "questions_options" ("is_correct") WHERE "is_correct" = 1;
CREATE INDEX "idx_tests" ON "tests" ("title");
CREATE INDEX "idx_questions" ON "questions" ("test_id", "id");
CREATE INDEX "idx_events" ON "events" ("type");

