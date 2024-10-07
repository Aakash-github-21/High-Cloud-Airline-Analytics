use excelr;

drop view maindata1;

CREATE VIEW maindata1 AS
    SELECT 
        CONCAT(year_, '-', month_, '-', day_) AS datefield,
        TransportedPassengers_,
        AvailableSeats,
        Carrier_Name,
        Departures_Performed,
        Airline_ID,
        From_To_City,
        Distance_,
        Year_,
   CASE
        WHEN availableseats = 0 THEN 0
        ELSE (transportedpassengers_ / availableseats) * 100
    END as load_factor_percentage
    FROM maindata;
SELECT * FROM maindata;
SELECT *FROM maindata1;

#------------------------------------------------------------------------------------------------------

                                      #KPI-1

drop view kpi1;
CREATE VIEW kpi1 AS
    SELECT 
        Datefield,
        YEAR(Datefield) AS years,
        MONTH(Datefield) AS month_no,
        DAY(datefield) AS day_no,
        MONTHNAME(datefield) AS MonthFullName,
        QUARTER(datefield) AS Quarters,
        CONCAT(YEAR(Datefield),'-',MONTHNAME(Datefield)) AS yearMonth,
        WEEK(datefield) AS WeekdayNO,
        DAYNAME(datefield) AS weekdayname,
        CASE
            WHEN MONTH(DateField) >= 4 THEN MONTH(datefield) - 3
            ELSE MONTH(datefield) + 9
        END AS Financial_month,
        CASE
            WHEN MONTH(DateField) IN (1 , 2, 3) THEN 'FQ-4'
            WHEN MONTH(DateField) IN (4 , 5, 6) THEN 'FQ-1'
            WHEN MONTH(DateField) IN (7 , 8, 9) THEN 'FQ-2'
            WHEN MONTH(DateField) IN (10 , 11, 12) THEN 'FQ-3'
            ELSE NULL
        END AS Financial_Quarter,
        TransportedPassengers_,
        AvailableSeats,
        Carrier_Name,
        Departures_Performed,
        Airline_ID,
        From_To_City,
        Distance_,
        Load_Factor_percentage,
        Year_,
        CASE
            WHEN Distance_ BETWEEN 0 AND 500 THEN '0-500 miles'
            WHEN Distance_ BETWEEN 501 AND 1000 THEN '501-1000 miles'
            WHEN Distance_ BETWEEN 1001 AND 1500 THEN '1001-1500 miles'
            WHEN Distance_ BETWEEN 1501 AND 2000 THEN '1501-2000 miles'
            WHEN Distance_ BETWEEN 2001 AND 2500 THEN '2001-2500 miles'
            WHEN Distance_ BETWEEN 2501 AND 3000 THEN '2501-3000 miles'
            WHEN Distance_ BETWEEN 3001 AND 3500 THEN '3001-3500 miles'
            WHEN Distance_ BETWEEN 3501 AND 4000 THEN '3501-4000 miles'
            WHEN Distance_ BETWEEN 4001 AND 4500 THEN '4001-4500 miles'
            WHEN Distance_ BETWEEN 4501 AND 5000 THEN '4501-5000 miles'
            WHEN Distance_ > 5001 THEN '> 5000 miles'
            ELSE 'Unknown'
        END AS Distance_Interval
    FROM
        Maindata1;
SELECT *FROM kpi1;
#------------------------------------------------------------------------------------------------------

                                                 #KPI-2

CREATE VIEW kpi2 AS
    SELECT 
        years, ROUND(AVG(Load_Factor_percentage), 2) as Yearwise
    FROM
        kpi1
    GROUP BY years;
SELECT * FROM kpi2;

SELECT 
   years, Month_no,
    ROUND(AVG(Load_Factor_percentage), 2) AS Month_wise
FROM
    kpi1
GROUP BY years,Month_no
ORDER BY years;
    
SELECT 
   years, Quarters,
    ROUND(AVG(Load_Factor_percentage), 2) AS Quarter_wise
FROM
    kpi1
GROUP BY years, Quarters
order by years;
-- --------------------------------Stored Producer------------------------------
drop procedure Load_Factor_Y;
delimiter //
create definer = root@localhost procedure Load_Factor_Y (in ipYear int)
begin 
SELECT 

    Year_,
    CONCAT(ROUND(SUM(AvailableSeats)/1000000, 2)," M") AS  'Total_no_of_Available_Seats', 
    CONCAT(ROUND(SUM(TransportedPassengers_)/1000000, 2)," M") AS Total_no_of_Transported_Passengers,
    CONCAT(ROUND(AVG(Load_Factor_percentage), 2)," %") AS "Load_Factor"
FROM
    maindata1
    where YEAR_ = ipyear
GROUP BY 1 ;
end // 
delimiter ;
-- --------------
call Load_Factor_Y (2008);

-- --------------------------------Month-Wise-----------------------------------

SELECT 
   years, Month_no,
    ROUND(AVG(Load_Factor_percentage), 2) AS Month_wise
FROM
    kpi1
GROUP BY years,Month_no
ORDER BY years;
-- --------------------------------Stored Producer------------------------------

Drop Procedure Load_Factor_M;
delimiter //
create definer = root@localhost procedure Load_Factor_M (in ipMonthNo int)
begin 
SELECT 
    month_no,
    CONCAT(ROUND(SUM(AvailableSeats)/1000000, 2)," M") AS  'Total_no_of_Available_Seats', 
    CONCAT(ROUND(SUM(TransportedPassengers_)/1000000, 2)," M") AS 'Total_no_of_Transported_Passengers',
    CONCAT(ROUND(AVG(Load_Factor_percentage), 2)," %") AS "Load_Factor"
FROM
    Kpi1
    where month_no = ipMonthNo
GROUP BY 1 ;
end // 
delimiter ;
-- --------------
call Load_Factor_M (12);

-- --------------------------------Quarter-Wise---------------------------------
SELECT 
   years, Quarters,
    ROUND(AVG(Load_Factor_percentage), 2) AS Quarter_wise
FROM
    kpi1
GROUP BY years, Quarters
order by years;

-- --------------------------------Stored Producer------------------------------
Drop Procedure Load_Factor_Q;
delimiter //
create definer = root@localhost procedure Load_Factor_Q (in ipquarterNo int)
begin 
SELECT 
    Quarters,
    CONCAT(ROUND(SUM(AvailableSeats)/1000000, 2)," M") AS  'Total_no_of_Available_Seats', 
    CONCAT(ROUND(SUM(TransportedPassengers_)/1000000, 2)," M") AS 'Total_no_of_Transported_Passengers',
    CONCAT(ROUND(AVG(Load_Factor_percentage), 2)," %") AS "Load_Factor"
FROM
    Kpi1
    where Quarters = ipquarterNo
GROUP BY 1 ;
end // 
delimiter ;
-- --------------
call Load_Factor_Q (3);



#------------------------------------------------------------------------------------------------------

                                                    #KPI-3
CREATE VIEW Kpi3 AS
    SELECT 
        Carrier_name,
        ROUND(AVG(Load_Factor_percentage), 2) AS Load_Factor_percentage
    FROM
        kpi1
    GROUP BY Carrier_name;
SELECT * FROM kpi3;

-- --------------------------------Stored Producer Yearwise filter Carrierwise L_F ------------------------------

drop procedure Yearwise_Carrier_Load_Factor;
delimiter //
create definer = root@localhost procedure Yearwise_Carrier_Load_Factor (in ipYear int)
begin 
SELECT 
    Year_ as 'Year_Wise', Carrier_Name, 
    ROUND(AVG(Load_Factor_percentage), 2) AS 'Avg_Load_Factor'
FROM
    KPI1
    WHERE YEAR_ = ipyear
GROUP BY 1,2
ORDER BY 1,3 desc;

end // 
delimiter ;
-- --------------
call Yearwise_Carrier_Load_Factor (2009);
#------------------------------------------------------------------------------------------------------

												  #KPI-4

CREATE VIEW Kpi4 AS
    SELECT 
	     carrier_name,
        ROUND(SUM(transportedpassengers_ / 1000000), 2) AS total_passengers
    FROM
        Kpi1
    GROUP BY carrier_name
    ORDER BY total_passengers DESC
    LIMIT 10;
SELECT * FROM kpi4;
#------------------------------------------------------------------------------------------------------
                                                  
                                                  #KPI-5
CREATE VIEW Kpi5 AS
    SELECT 
        From_To_City, COUNT(Departures_Performed) AS No_Of_Flights
    FROM
        maindata
    GROUP BY from_to_city
    ORDER BY No_Of_Flights DESC
    LIMIT 5;
SELECT * FROM kpi5;  

#------------------------------------------------------------------------------------------------------

									            #KPI-6

CREATE VIEW Days AS
    SELECT 
        Load_Factor_Percentage,
        CASE
            WHEN DAYOFWEEK(datefield) IN (1 , 7) THEN 'Weekend'
            ELSE 'Weekdays'
        END AS Weekend_Weekdays
    FROM
        maindata1;
  

CREATE VIEW kpi6 AS
    SELECT 
        Weekend_Weekdays,
        CONCAT(ROUND(COUNT(Load_Factor_Percentage) / 1000, 2),
                '%') AS 'Loads'
    FROM days
    GROUP BY Weekend_Weekdays
    ORDER BY Loads;

SELECT * FROM  kpi6;

#------------------------------------------------------------------------------------------------------
                                            #kpi7

CREATE VIEW KPI7 AS
    SELECT 
        distance_interval,
        COUNT(Departures_Performed) AS No_Of_flights
    FROM
        KPI1
    GROUP BY distance_interval;

SELECT * FROM KPI7;


                                    
                                    
                                    
                                    
                                    
                                    