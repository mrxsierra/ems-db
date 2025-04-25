-- # Create/Reset database schema
-- Drop views if exists
DROP VIEW IF EXISTS `tests_history`;
DROP VIEW IF EXISTS `test_questions_option_search`;
DROP VIEW IF EXISTS `test_sessions_suspicious_behaviour_search`;

-- Drop index if exists
-- DROP INDEX idx_reports ON reports;
-- DROP INDEX idx_events ON events;
-- DROP INDEX idx_tests_sessions ON tests_sessions;
-- DROP INDEX idx_tests_sessions_status ON tests_sessions;
-- DROP INDEX idx_questions_options_is_correct ON questions_options;
-- DROP INDEX idx_questions_options ON questions_options;
-- DROP INDEX idx_questions ON questions;
-- DROP INDEX idx_tests ON tests;
-- DROP INDEX idx_students ON students;

-- Drop tables if exists
DROP TABLE IF EXISTS `reports`;
DROP TABLE IF EXISTS `results`;
DROP TABLE IF EXISTS `events`;
DROP TABLE IF EXISTS `proctoring_sessions`;
DROP TABLE IF EXISTS `proctors`;
DROP TABLE IF EXISTS `tests_sessions`;
DROP TABLE IF EXISTS `questions_options`;
DROP TABLE IF EXISTS `questions`;
DROP TABLE IF EXISTS `tests`;
DROP TABLE IF EXISTS `students`;

-- CREATE TABLES
-- Represents students taking the test
CREATE TABLE IF NOT EXISTS
    `students` (
        `id` INT AUTO_INCREMENT,
        `first_name` VARCHAR(100) NOT NULL,
        `last_name` VARCHAR(100) NOT NULL,
        `password` VARCHAR(255) NOT NULL,
        `email` VARCHAR(255) NOT NULL UNIQUE,
        PRIMARY KEY (`id`)
    );

-- Represents tests available in system
CREATE TABLE IF NOT EXISTS
    `tests` (
        `id` INT AUTO_INCREMENT,
        `title` VARCHAR(300) NOT NULL UNIQUE,
        `description` VARCHAR(300) NOT NULL,
        `duration` TIME NOT NULL,
        `instructions` TEXT NOT NULL,
        `course` VARCHAR(32) NOT NULL,
        PRIMARY KEY (`id`)
    );

-- Represents questions in tests
-- support multiple choice and true/false
CREATE TABLE IF NOT EXISTS
    `questions` (
        `id` INT AUTO_INCREMENT,
        `test_id` INT,
        `question` TEXT NOT NULL,
        `type` VARCHAR(32) NOT NULL,
        `topic` VARCHAR(32) NOT NULL,
        `duration` TIME NOT NULL,
        PRIMARY KEY (`id`),
        FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`)
    );

-- Represents options for multiple-option questions
CREATE TABLE IF NOT EXISTS
    `questions_options` (
        `id` INT AUTO_INCREMENT,
        `question_id` INT,
        `option` TEXT NOT NULL,
        `is_correct` TINYINT (1) NOT NULL DEFAULT '0',
        PRIMARY KEY (`id`),
        FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`)
    );

-- Represents sessions in which users take tests
CREATE TABLE IF NOT EXISTS
    `tests_sessions` (
        `id` INT AUTO_INCREMENT,
        `test_id` INT,
        `student_id` INT,
        `start` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `end` DATETIME, -- trigger added.
        `duration_taken` TIME, -- trigger added
        `status` ENUM ('in-progress', 'ended', 'completed') NOT NULL DEFAULT 'in-progress',
        PRIMARY KEY (`id`),
        FOREIGN KEY (`test_id`) REFERENCES `tests` (`id`),
        FOREIGN KEY (`student_id`) REFERENCES `students` (`id`)
    );

-- Represents individuals who supervises test sessions
CREATE TABLE IF NOT EXISTS
    `proctors` (
        `id` INT AUTO_INCREMENT,
        `first_name` VARCHAR(32) NOT NULL,
        `last_name` VARCHAR(32) NOT NULL,
        `password` VARCHAR(32) NOT NULL,
        `email` VARCHAR(32) NOT NULL UNIQUE,
        PRIMARY KEY (`id`)
    );

-- Represents sessions in which proctors supervise test sessions
CREATE TABLE IF NOT EXISTS
    `proctoring_sessions` (
        `id` INT AUTO_INCREMENT,
        `proctor_id` INT,
        `test_session_id` INT,
        `start` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `end` DATETIME, -- trigger added
        `status` ENUM ('active', 'completed') NOT NULL DEFAULT 'active',
        PRIMARY KEY (`id`),
        FOREIGN KEY (`test_session_id`) REFERENCES `tests_sessions` (`id`),
        FOREIGN KEY (`proctor_id`) REFERENCES `proctors` (`id`)
    );

-- Represents events occurring during proctoring sessions
-- trigger added for some new auto updates and entries
CREATE TABLE IF NOT EXISTS
    `events` (
        `id` INT AUTO_INCREMENT,
        `proctoring_session_id` INT,
        `type` ENUM (
            'started-test',
            'completed-test',
            'ended-test',
            'suspicious-behavior'
        ) NOT NULL,
        `timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `description` VARCHAR(32) DEFAULT 'OK',
        PRIMARY KEY (`id`),
        FOREIGN KEY (`proctoring_session_id`) REFERENCES `proctoring_sessions` (`id`)
    );

-- Represents the results of test sessions
-- trigger added for some new auto updates adn entries
CREATE TABLE IF NOT EXISTS
    `results` (
        `id` INT AUTO_INCREMENT,
        `test_session_id` INT,
        `question_id` INT,
        `answer` INT NOT NULL,
        `score` TINYINT(1) NOT NULL DEFAULT 0,
        `feedback` VARCHAR(255),
        PRIMARY KEY (`id`),
        FOREIGN KEY (`test_session_id`) REFERENCES `tests_sessions` (`id`),
        FOREIGN KEY (`question_id`) REFERENCES `questions` (`id`),
        FOREIGN KEY (`answer`) REFERENCES `questions_options` (`id`)
    );


-- Represents reports generated for test sessions
CREATE TABLE IF NOT EXISTS
    `reports` (
        `id` INT AUTO_INCREMENT,
        `test_session_id` INT,
        `total_score` INT,
        `final_score` INT, -- trigger added.
        `overall_feedback` VARCHAR(32), -- trigger added.
        PRIMARY KEY (`id`),
        FOREIGN KEY (`test_session_id`) REFERENCES `tests_sessions` (`id`)
    );

-- CREATE TRIGGERS: to UPDATE and INSERT values
DELIMITER $$
-- Create a trigger to set the end time based on the tests duration
CREATE TRIGGER `set_end_for_test_session` BEFORE INSERT ON
`tests_sessions` FOR EACH ROW
BEGIN
    SET NEW.end = DATE_ADD(
        IFNULL(NEW.start, NOW()),
        INTERVAL (
            SELECT TIME_TO_SEC(`duration`) / 60 FROM `tests` WHERE `id` = NEW.`test_id`
        ) MINUTE
    );
END$$

-- Create a trigger to add events for when test session started
CREATE TRIGGER `add_events_starts` AFTER INSERT ON `proctoring_sessions` FOR EACH ROW
BEGIN
    INSERT INTO
        `events` (`proctoring_session_id`, `type`)
    VALUES
        (NEW.id, 'started-test');
END$$

-- Create a trigger to set score for answer of questions
CREATE TRIGGER `set_score_of_result` BEFORE INSERT ON
`results` FOR EACH ROW
BEGIN
    SET NEW.score = (
        SELECT is_correct FROM questions_options WHERE id = NEW.answer
    );
    SET NEW.feedback = CASE
        WHEN (
            SELECT is_correct FROM questions_options WHERE id = NEW.answer
        ) = 0 THEN 'need-improvement'
        ELSE 'great'
    END;
END$$

-- Create a trigger to update tests sessions, events, proctoring session and reports on tests session status update
CREATE TRIGGER `update_status_end_final_score_all` BEFORE UPDATE ON
`tests_sessions` FOR EACH ROW
BEGIN
    IF (NEW.status IN ('ended', 'completed') AND OLD.status NOT IN ('ended', 'completed')) THEN
        -- Set the duration taken
        SET NEW.duration_taken = TIMEDIFF(NOW(), NEW.start);

        -- Add event for test session (find proctoring session for this test session)
        INSERT INTO `events` (`proctoring_session_id`, `type`)
        SELECT `id`,
            CASE
                WHEN NEW.status = 'ended' THEN 'ended-test'
                ELSE 'completed-test'
            END
        FROM `proctoring_sessions`
        WHERE `test_session_id` = NEW.id
        LIMIT 1;

        -- Update end time and status for proctoring session
        UPDATE `proctoring_sessions`
        SET
            `end` = CURRENT_TIMESTAMP,
            `status` = 'completed'
        WHERE
            `test_session_id` = NEW.id
            AND `status` = 'active';

        -- Add reports for test session
        INSERT INTO `reports` (
            `test_session_id`,
            `total_score`,
            `final_score`,
            `overall_feedback`
        )
        VALUES (
            NEW.id,
            (SELECT COUNT(*) FROM `results` WHERE `test_session_id` = NEW.id),
            (SELECT IFNULL(SUM(`score`),0) FROM `results` WHERE `test_session_id` = NEW.id),
            (SELECT MAX(`feedback`) FROM `results` WHERE `test_session_id` = NEW.id)
        );
    END IF;
END$$
DELIMITER ;

-- end of trigger
-- CREATE VIEWS: to simplify quering
-- VIEW all students test performance history in test they took
CREATE VIEW
    `tests_history` AS
SELECT
    `TS`.`student_id`,
    `T`.`title` AS `test_title`,
    `R`.`total_score`,
    `R`.`final_score` AS `scored`,
    `R`.`overall_feedback`,
    `TS`.`duration_taken`
FROM
    `reports` AS `R`
    JOIN `tests_sessions` AS `TS` ON `R`.`test_session_id` = `TS`.`id`
    JOIN `tests` AS `T` ON `TS`.`test_id` = `T`.`id`;

-- VIEW all tests and their questions as well as options
CREATE VIEW
    `test_questions_option_search` AS
SELECT
    `T`.`title`,
    `T`.`description`,
    `T`.`duration` `test_duration`,
    `T`.`course`,
    `Q`.`question`,
    `Q`.`type`,
    `Q`.`topic`,
    `Q`.`duration` `time_to_solve`,
    `QO`.`option`,
    `QO`.`is_correct`
FROM
    `tests` `T`
    JOIN `questions` `Q` ON `Q`.`test_id` = `T`.`id`
    JOIN `questions_options` `QO` ON `QO`.`question_id` = `Q`.`id`;

-- VIEW tests session of suspicious behaviour
CREATE VIEW
    `test_sessions_suspicious_behaviour_search` AS
SELECT
    `PS`.`test_session_id`,
    `TS`.`student_id`,
    `TS`.`duration_taken`,
    `TS`.`status` `test_session_status`,
    `PS`.`proctor_id`,
    `E`.`proctoring_session_id`,
    `E`.`type`,
    `E`.`timestamp`,
    `E`.`description`
FROM
    `tests_sessions` `TS`
    JOIN `proctoring_sessions` `PS` ON `TS`.`id` = `PS`.`test_session_id`
    JOIN `events` `E` ON `PS`.`id` = `E`.`proctoring_session_id`
WHERE
    `E`.`type` = 'suspicious-behavior';

-- CREATE INDEXES: to speed common searches
CREATE INDEX `idx_tests_sessions` ON `tests_sessions` (`student_id`, `test_id`, `id`);

CREATE INDEX `idx_tests_sessions_status` ON `tests_sessions` (`status`);

CREATE INDEX `idx_reports` ON `reports` (`test_session_id`, `id`);

CREATE INDEX `idx_students` ON `students` (`first_name`, `last_name`, `email`);

CREATE INDEX `idx_questions_options` ON `questions_options` (`question_id`, `is_correct`);

CREATE INDEX `idx_questions_options_is_correct` ON `questions_options` (`is_correct`);

CREATE INDEX `idx_tests` ON `tests` (`title`);

CREATE INDEX `idx_questions` ON `questions` (`test_id`, `id`);

CREATE INDEX `idx_events` ON `events` (`type`);


-- check errors
SHOW WARNINGS;
SHOW ERRORS;