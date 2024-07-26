DELIMITER //

CREATE PROCEDURE AllocateSubjects()
BEGIN
    DECLARE finished INT DEFAULT 0;
    DECLARE student_id INT;
    DECLARE student_gpa DECIMAL(3, 1);
    DECLARE preference INT;
    DECLARE subject_id VARCHAR(10);
    DECLARE subject_name VARCHAR(50);
    DECLARE max_seats INT;
    DECLARE remaining_seats INT;

    -- Cursor to select students ordered by GPA in descending order
    DECLARE student_cursor CURSOR FOR
        SELECT StudentId, GPA FROM StudentDetails ORDER BY GPA DESC;

    -- Cursor to select each student's preferences
    DECLARE preference_cursor CURSOR FOR
        SELECT SubjectId, Preference FROM StudentPreference WHERE StudentId = student_id ORDER BY Preference;

    -- Handler for cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    OPEN student_cursor;

    -- Loop through each student based on GPA
    student_loop: LOOP
        FETCH student_cursor INTO student_id, student_gpa;
        IF finished THEN 
            LEAVE student_loop;
        END IF;

        SET finished = 0;  -- Reset the finished flag for the preference loop
        OPEN preference_cursor;

        -- Loop through each preference for the current student
        preference_loop: LOOP
            FETCH preference_cursor INTO subject_id, preference;
            IF finished THEN 
                -- If no preferences can be fulfilled, mark as unallotted
                INSERT INTO UnallotedStudents (StudentId) VALUES (student_id);
                LEAVE preference_loop;
            END IF;

            -- Check if there are available seats for the subject
            SELECT RemainingSeats INTO remaining_seats
            FROM SubjectDetails
            WHERE SubjectId = subject_id;

            IF remaining_seats > 0 THEN
                -- Allocate the subject to the student
                INSERT INTO Allotments (SubjectId, StudentId) VALUES (subject_id, student_id);

                -- Update the remaining seats for the subject
                UPDATE SubjectDetails
                SET RemainingSeats = RemainingSeats - 1
                WHERE SubjectId = subject_id;

                LEAVE preference_loop;  -- Exit the preference loop once allotted
            END IF;
        END LOOP preference_loop;

        CLOSE preference_cursor;
    END LOOP student_loop;

    CLOSE student_cursor;
END //

DELIMITER ;