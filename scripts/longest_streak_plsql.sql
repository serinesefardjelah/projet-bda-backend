-------------------------------------------
-- Creating the function longest_streeak --
-------------------------------------------

CREATE OR REPLACE FUNCTION longest_streak RETURN SYS_REFCURSOR AS
    prev_date TIMESTAMP (6) WITH TIME ZONE;
    curr_date TIMESTAMP (6) WITH TIME ZONE;
    streak_start_date TIMESTAMP (6) WITH TIME ZONE;
    max_streak_length INTEGER := 0;
    current_streak_length INTEGER := 0;
    start_date TIMESTAMP (6) WITH TIME ZONE;
    end_date TIMESTAMP (6) WITH TIME ZONE;
    streak_length INTEGER;
    longest_streak_cur SYS_REFCURSOR;
BEGIN
    -- Initialize variables
    prev_date := NULL;
    streak_start_date := NULL;

    -- Iterate through the rows ordered by start_date_local
    FOR activity_rec IN (SELECT TRUNC(TO_TIMESTAMP_TZ(START_DATE_LOCAL, 'DD-MON-YY HH.MI.SS.FF9 AM TZR')) AS activity_date
                         FROM ACTIVITIES
                         ORDER BY TRUNC(TO_TIMESTAMP_TZ(START_DATE_LOCAL, 'DD-MON-YY HH.MI.SS.FF9 AM TZR'))) LOOP
        curr_date := activity_rec.activity_date;

        -- Check if this is the first date or if it's consecutive to the previous one
        IF prev_date IS NULL OR curr_date = prev_date + INTERVAL '1' DAY THEN
            IF streak_start_date IS NULL THEN
                streak_start_date := curr_date;
            END IF;
            current_streak_length := current_streak_length + 1;
        ELSE
            -- Check if the current streak is longer than the max streak
            IF current_streak_length > max_streak_length THEN
                max_streak_length := current_streak_length;
                start_date := streak_start_date;
                end_date := prev_date;
                streak_length := max_streak_length;
            END IF;
            -- Reset streak variables
            streak_start_date := curr_date;
            current_streak_length := 1;
        END IF;

        -- Update previous date
        prev_date := curr_date;
    END LOOP;

    -- Check if the last streak is longer than the max streak
    IF current_streak_length > max_streak_length THEN
        max_streak_length := current_streak_length;
        start_date := streak_start_date;
        end_date := prev_date;
        streak_length := max_streak_length;
    END IF;

    -- Open a cursor and return the longest streak details
    OPEN longest_streak_cur FOR
        SELECT start_date, end_date, streak_length
        FROM DUAL;

    RETURN longest_streak_cur;
END;


-----------------------------------------
-- Calling the function longest_streak --
-----------------------------------------

SET SERVEROUTPUT ON;

DECLARE
    longest_streak_cur SYS_REFCURSOR;
    start_date TIMESTAMP (6) WITH TIME ZONE;
    end_date TIMESTAMP (6) WITH TIME ZONE;
    streak_length INTEGER;
BEGIN
    -- Call the function and retrieve the cursor
    longest_streak_cur := longest_streak();

    -- Fetch the results from the cursor into variables
    FETCH longest_streak_cur INTO start_date, end_date, streak_length;

    -- Close the cursor
    CLOSE longest_streak_cur;

    -- Output the results
    DBMS_OUTPUT.PUT_LINE('Longest Streak:');
    DBMS_OUTPUT.PUT_LINE('Start Date: ' || TO_CHAR(start_date, 'DD-MON-YY'));
    DBMS_OUTPUT.PUT_LINE('End Date: ' || TO_CHAR(end_date, 'DD-MON-YY'));
    DBMS_OUTPUT.PUT_LINE('Streak Length: ' || streak_length);
END;