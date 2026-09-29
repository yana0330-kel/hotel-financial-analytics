--создаем вьюшку отвечающую на бизнес-вопрос 1
CREATE OR REPLACE VIEW dm_question_1 AS
SELECT 
    d.hotel_name
    , DATE_TRUNC('month', fb.arrival_date)::DATE AS date
    , SUM(fb.sales) AS total_revenue
    , COUNT(fb.booking_id) AS count_booking
FROM fact_bookings fb
JOIN dim_hotel AS d ON fb.hotel_id = d.hotel_id
GROUP BY 1, DATE_TRUNC('month', fb.arrival_date)::DATE
ORDER BY date;

SELECT * FROM dm_question_1;

--создаем вьюшку отвечающую на бизнес-вопрос 2
CREATE OR REPLACE VIEW dm_question_2 AS
SELECT
    dc.dis_channel -- ИСПРАВЛЕНО: было channel_name
    , DATE_TRUNC('month', fb.arrival_date)::DATE AS date
    , ROUND(SUM(fb.sales - fb.comm_amt), 2) AS net_profit
    , ROUND(AVG(fb.sales - fb.comm_amt), 2) AS avg_profit_per_booking
    , ROUND(SUM(fb.sales), 2) AS total_revenue
FROM fact_bookings AS fb
JOIN dim_channel AS dc ON fb.channel_id = dc.channel_id
GROUP BY 1, 2
ORDER BY date;

SELECT * FROM dm_question_2;

--создаем вьюшку отвечающий на бизнес-вопрос 3
CREATE OR REPLACE VIEW dm_question_3 AS
SELECT
    dh.hotel_name
    , DATE_TRUNC('month', fb.arrival_date)::DATE AS date
    , ROUND(AVG(fb.nights), 2) AS avg_counts_nights -- ИСПРАВЛЕНО: используем готовое поле nights вместо разности дат с опечаткой depature_date
    , ROUND(AVG(fb.calculated_adr), 2) AS avg_adr
FROM fact_bookings AS fb
JOIN dim_hotel AS dh ON fb.hotel_id = dh.hotel_id
GROUP BY 1, 2
ORDER BY date;

SELECT * FROM dm_question_3;

--создаем вьюшку отвечающий на бизнес-вопрос 4
CREATE OR REPLACE VIEW dm_question_4 AS
SELECT
    fb.cus_seg -- ИСПРАВЛЕНО: было customer_segment
    , DATE_TRUNC('month', fb.arrival_date)::DATE AS month
    , dc.membership
    , SUM(fb.sales) AS total_revenue
    , COUNT(fb.booking_id) AS count_booking
FROM fact_bookings fb
JOIN dim_customer dc ON fb.customer_id = dc.customer_id
GROUP BY 1, 2, 3
ORDER BY month;

SELECT * FROM dm_question_4;

--создаем вьюшку отвечающий на бизнес-вопрос 5
CREATE OR REPLACE VIEW dm_question_5 AS 
SELECT 
	DATE_TRUNC('month', fb.arrival_date)::DATE AS date
  , CASE WHEN fb.disc_amt = 0 THEN 'No Discount' ELSE 'Discount Applied' END AS discount_category
  , COUNT(fb.booking_id) AS count_booking
  , ROUND(AVG(fb.customer_rating), 2) AS avg_rating
FROM
	fact_bookings AS fb
GROUP BY 1,2
ORDER BY 1;

SELECT * FROM dm_question_5;