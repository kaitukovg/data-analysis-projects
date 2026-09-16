DECLARE
    counter INTEGER := 0;     
    i INTEGER := 1;            
    current_char TEXT;         
BEGIN
    LOOP
        current_char := SUBSTR(busy_days, i, 1);
       
        EXIT WHEN current_char = '';

        IF current_char >= '0' AND current_char <= '9' THEN
            counter := counter + 1;
        END IF;
        
        i := i + 1;
    END LOOP;
    RETURN counter;
END;



BEGIN
    RETURN QUERY
    SELECT 
        id, 
        flight_num, 
        start_date, 
        end_date, 
        days::TEXT, 
        get_busy_days_count(days) 
    FROM public.schedule
    ORDER BY 6 DESC; 
END;
