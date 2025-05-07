# Design Document

By Sunil Sharma `CS50S Final Submission`

Video overview: [EMS - Youtube Video](https://youtu.be/CRT4_j3kZes)

## Scope

The purpose of the database is to manage a system for conducting tests and examinations. It includes all entities necessary to conduct tests, proctor test taker and producing results and reports of student performance. scope of database include:

* ***Students :*** Individuals taking tests basic info.
* ***Tests :*** Include basic info of tests/Examination, type and duration.
* ***Questions :*** Includes info about questions and their type.
* ***Questions options :*** Includes info about questions options and correctness.
* ***Test sessions :*** Instances of students taking tests, their status and time taken.
* ***Proctors :*** Individuals overseeing and monitoring test sessions.
* ***Proctoring sessions :*** Supervised sessions conducted by proctors during tests.
* ***Events :*** Records of activities and occurrences during test sessions.
* ***Reports :*** Summaries of test session results.
* ***Results :*** Outcomes of student responses to test questions.

***"The database focuses on managing the administration, execution, and monitoring of tests and examinations and focus only some core process of making tests sets of multiple option questions."***

> ***Warning :*** Database is not designed to handle all aspects of educational management. *eg. like **user log acitivity, notifying user, finacial aspects, subjective answer type and many other aspect of proctoring and adminstration.***

## Functional Requirements

This database will support:

* ***CRUD operation*** for students, tests, proctors, questions and their options.
* ***Create and manage tests***, including setting instructions, duration, and questions.
* ***Assign tests*** to students and test sessions.
* ***Monitor and manage test sessions***, including tracking student progress and proctoring activities.
* ***View and analyze test results***, including scores, feedback, and overall performance.
* ***Generate reports*** summarizing test session outcomes.
* **Record and review events** occurring during test sessions, such as suspicious behavior or test completion.

## Representation

Entities are captured in **SQLite** tables with the following schema.

### Entities

The database includes following entities:

#### Students

The `students` includes the following attributes:

* `id`: An `INTEGER` unique identifier for each student of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `first_name`: This field stores the first name. It is of type `TEXT` to accommodate alphanumeric characters typically found in names.
* `last_name`: stores the last name of the student. It is also of type `TEXT`.
* `password`: Stores the password for student authentication. As it contains sensitive information, it is stored as `TEXT`. In a real-world scenario, it should be encrypted for security purposes.
* `email`: Represents the email address of the student, used for communication and authentication. It is of type `TEXT` and has a `UNIQUE` constraint applied.

All columns in the `students` table are required and hence should have the `NOT NULL` constraint applied. No other constraints are necessary.

#### Tests

The `tests` table has the following attributes:

* `id`: Unique identifier for each test of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `title`: Stores the title or name of the test. It is of type `TEXT` and has a `UNIQUE` constraint to ensure each test has a unique title.
* `description`: Provides a brief description of the test. It is of type `TEXT`.
* `duration`: Represents the duration of the test, typically in minutes. It is of type `NUMERIC` to allow for decimal values if needed.
* `instructions`: Contains instructions or guidelines for taking the test. It is of type `TEXT`.
* `course`: Indicates the course associated with the test. It is of type `TEXT`.

All columns in the `tests` table are required and hence should have the `NOT NULL` constraint applied. No other constraints are necessary.

#### Questions

The `questions` table includes the following attributes:

* `id`: A unique identifier for each question of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `test_id`: Represents the test to which the question belongs. It is a `FOREIGN KEY` referencing the `id` column in the `tests` table.
* `question`: Stores the actual question text. It is of type `TEXT`.
* `type`: Specifies the type of question, such as multiple choice or true/false. It is of type `TEXT`.
* `topic`: Represents the topic or category to which the question belongs. It is of type `TEXT`.
* `duration`: Indicates the duration allocated for answering the question, typically in seconds. It is of type `NUMERIC`.

All columns in the `questions` table are required and hence should have the `NOT NULL` constraint applied. No other constraints are necessary.

#### Questions Options

The `questions_options` table includes the following attributes:

* `id`: A unique identifier for each option of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `question_id`: Represents the question to which the option belongs. It is a `FOREIGN KEY` referencing the `id` column in the `questions` table.
* `option`: Stores the text of the option. It is of type `TEXT`.
* `is_correct`: Indicates whether the option is correct or not of type `INTEGER` (`0` for incorrect, `1` for correct) and has a `CHECK` constraint to ensure valid values.

All columns in the `questions_options` table are required and hence should have the `NOT NULL` constraint applied. No other constraints are necessary.

#### Tests Sessions

The `tests_sessions` table includes the following attributes:

* `id`: A unique identifier for each test session of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `test_id`: Represents the test being taken in the session. It is a `FOREIGN KEY` referencing the `id` column in the `tests` table.
* `student_id`: Represents the student taking the test session. It is a `FOREIGN KEY` referencing the `id` column in the `students` table.
* `start`: Indicates the start time of the test session. It is of type `NUMERIC` and has a default value of the current timestamp.
* `end`: Represents the end time of the test session. It is of type `NUMERIC` and may be null until the session is completed.
* `duration_taken`: Stores the duration taken for the test session. It is of type `NUMERIC` and may be calculated based on `start` and `end` timestamps.
* `status`: Indicates the status of the test session (in-progress, ended, completed). It is of type `TEXT` and has a `CHECK` constraint to ensure valid values.

All columns in the `tests_sessions` table are required and hence should have the `NOT NULL` constraint applied excepts for `end` and `duration_taken` which will be handled by their respective triggers(`set_end_for_test_session` and `update_status_end_final_score_all`).

Where in `end` calculated by `CURRENT_TIMESTAMP` + `duration` assigned in `tests`. where as `duration_taken` is updated when `status` is changed to `completed`, its time difference of `start` and time at status change.

Also `status` has `DEFAULT` value `in-progress` indicating session status and check constraint to limit values to (`in-progress`, `ended`, `completed`) which can updated when `students` complete `tests`.

#### Proctors

The `proctors` table includes the following attributes:

* `id`: A unique identifier for each proctor of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `first_name`: Stores the first name of the proctor. It is of type `TEXT`.
* `last_name`: Stores the last name of the proctor. It is also of type `TEXT`.
* `password`: Stores the password for proctor authentication. It is of type `TEXT`.
* `email`: Represents the email address of the proctor, used for communication and authentication. It is of type `TEXT` and has a `UNIQUE` constraint applied.

All columns in the `proctors` table are required and hence should have the `NOT NULL` constraint applied. No other constraints are necessary.

#### Proctoring Sessions

The `proctoring_sessions` table includes the following attributes:

* `id`: A unique identifier for each proctoring session of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `proctor_id`: Represents the proctor supervising the session. It is a `FOREIGN KEY` referencing the `id` column in the `proctors` table.
* `test_session_id`: Represents the test session being supervised. It is a `FOREIGN KEY` referencing the `id` column in the `tests_sessions` table.
* `start`: Indicates the start time of the proctoring session. It is of type `NUMERIC` and has a default value of the current timestamp.
* `end`: Represents the end time of the proctoring session. It is of type `NUMERIC` and may be null until the session is completed.
* `status`: Indicates the status of the proctoring session (active, completed). It is of type `TEXT` and has a `CHECK` constraint to ensure valid values.

All columns in the `proctoring_sessions` table are required and hence should have the `NOT NULL` constraint applied excepts for `end` which will be handled by trigger(`update_status_end_final_score_all`).

Where in `end` calculated by `CURRENT_TIMESTAMP`, when `status` is changed to `completed` in `proctoring_sessions`.

And where as `status` has `DEFAULT` value `active` indicating session status and check constraint to limit values to (`active`, `completed`) which can updated when `students` complete `tests`.

#### Events

The `events` table includes the following attributes:

* `id`: A unique identifier for each event of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `proctoring_session_id`: Represents the proctoring session associated with the event. It is a `FOREIGN KEY` referencing the `id` column in the `proctoring_sessions` table.
* `type`: Indicates the type of event (started-test, completed-test, ended-test, suspicious-behavior). It is of type `TEXT` and has a `CHECK` constraint to ensure valid values.
* `timestamp`: Represents the timestamp when the event occurred. It is of type `NUMERIC` and has a default value of the current timestamp.
* `description`: Provides additional description or details about the event. It is of type `TEXT` and has a default value of 'OK'.

`events` are mostly handled by triggers(`set_score_of_result` and `update_status_end_final_score_all`), only in case when `suspicious-behaviour` detected, than can be needed to inserted manually, which involve `INSERT` only `proctoring_session_id`, `type` and `description`, since `timestamp` has DEFAULT `CURRENT_TIMESTAMP`.

Having said that now!.. `NOT NULL` constraint only applies to all excepts `description` which has `DEFAULT` value `OK`, which only needed to be changed, IN case when `type` (which has check constraint (`started-test`, `completed-test`, `ended-test`, `suspicious-behavior`) and has `DEFAULT` value `started-test`), which is updated to `suspicious-behavior` which can be done manually.

Now in case when student have no `suspicious-behavior`. then in that case `status` is normally updated to `ended` or `completed` based on `status` of `tests_sessions` and decription has `DEFAULT` value `OK` to indiacate normal activity.

#### Results

The `results` table includes the following attributes:

* `id`: A unique identifier for each result of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `test_session_id`: Represents the test session associated with the result. It is a `FOREIGN KEY` referencing the `id` column in the `tests_sessions` table.
* `question_id`: Represents the question associated with the result. It is a `FOREIGN KEY` referencing the `id` column in the `questions` table.
* `answer`: Represents the chosen answer option for the question. It is a `FOREIGN KEY` referencing the `id` column in the `questions_options` table.
* `score`: Indicates the score obtained for the question (0 for incorrect, 1 for correct). It is of type `INTEGER` and has a `CHECK` constraint to ensure valid values.
* `feedback`: Provides feedback related to the answer. It is of type `TEXT`.

ALL the answer of test question is stored in `answer` attributes which takes `questions_options` table `id`'s with `test_session_id` and `question_id` REFERENCES. `score` and `feedback` is handled by trigger(`set_score_of_result`) which is based on `is_coorect` column for `score` to check if it's correct option or not, and `feedback` is based on correctness `score` (i.e `is_correct`) such that if option is incorrect feedback is set to `need-improvement` else `great`. `NOT NULL` constraint is applied to all excepts `feedback`.

#### Reports

The `reports` table includes the following attributes:

* `id`: A unique identifier for each report of type `INTEGER`. It is the `PRIMARY KEY` of the table, thus its constraint applied.
* `test_session_id`: Represents the test session associated with the report. It is a `FOREIGN KEY` referencing the `id` column in the `tests_sessions` table.
* `total_score`: Indicates the total score achieved in the test session. It is of type `INTEGER`.
* `final_score`: Represents the final score of the test session. It is of type `INTEGER`.
* `overall_feedback`: Provides overall feedback for the test session. It is of type `TEXT`.

All insertion in `reports` handled by trigger (`update_status_end_final_score_all`). Hence no `NOT NULL` constraint required.

### Relationships

The below entity relationship diagram describes the relationships among the entities in the database.

![ER Diagram](/assets/erDiagram-old.png)

As detailed by the diagram:

* `Students` have a one-to-many relationship with `test sessions`. A student may have zero test sessions (if they haven't participated in any tests yet) or many test sessions (if they've taken multiple tests or repeated the same test). Each `test session` belongs to exactly one student.

* `Tests` have a one-to-many relationship with both `questions` and `test sessions`. A test may have zero questions (when newly created) or many questions. Similarly, a test may have zero test sessions (if not yet taken by any student) or many test sessions (taken by multiple students). Each `question` and `test session` belongs to exactly one test.

* `Questions` have a one-to-many relationship with `question options`. A question may have zero options (when first created) or many options. Each `question option` belongs to exactly one question. Questions also have a one-to-many relationship with `results`, where one question can be answered in multiple results from different test sessions.

* `Test sessions` have:
  * A one-to-many relationship with `results` (zero results when no questions answered, many when questions are answered)
  * A one-to-one relationship with `reports` (a test session may have zero or one report)
  * A one-to-many relationship with `proctoring sessions` (a test session is monitored by one or more proctoring sessions)

* `Results` have a many-to-one relationship with both `questions` and `test sessions`. Each result belongs to exactly one question and one test session.

* `Proctoring sessions` have:
  * A many-to-one relationship with `proctors` (each proctoring session is monitored by exactly one proctor)
  * A many-to-one relationship with `test sessions` (each proctoring session monitors exactly one test session)
  * A one-to-many relationship with `events` (a proctoring session may record zero or many events)

* `Proctors` have a one-to-many relationship with `proctoring sessions`. A proctor may monitor zero or many proctoring sessions.

## Optimizations

Several optimizations were made in the schema:

### ***Indexes***

* Indexes were created on various columns used frequently in queries to improve query performance. For example, indexes were added on columns like `student_id`, `test_id`, `question_id`, `is_correct`, etc. many other mentioned in in `schema.sql` for other table, based on several query mentioned in `queries.sql` can be seen their.
* The purpose of adding indexes is to speed up common search operations, especially when filtering or joining large datasets.

### ***Views***

* Views were created to simplify querying for common tasks. For example, the `tests_history` view provides a consolidated view of students' test performance history, while the `test_questions_option_search` view simplifies searching for tests and their associated questions and options and `test_sessions_suspicious_behaviour_search` view provides tests sessions where suspicious activity occured.
* This views help in abstracting complex queries into simpler, reusable forms, enhancing the database's usability and reducing the complexity of queries for end-users.

> ***These optimizations were implemented to improve the overall performance and usability of the database system by reducing query execution time and simplifying the querying process.***

## Limitations

The current schema focuses only on some core process of test conducting, report generating and proctoring. ***It lacks other question type like subjective (long answers), which will require some change in database. It does not focuses administrative process of securing account and role based security on database.***

### ***`Read :`***

> * [`README.md`](/README.md) `<<<` For explore more details about the project.
> * [`1-schema-diff.md`](/docs/1-schema-diff.md) `<<<` for schema related differences.
> * [`2-query-interection-diff.md`](/docs/2-query-interection-diff.md) `<<<` for query related differences.

## Conclusion

Overall the current design meets the immediate requirements outlined, it may face challenges in handling more complex scenarios or evolving use cases without further refinement or expansion.
