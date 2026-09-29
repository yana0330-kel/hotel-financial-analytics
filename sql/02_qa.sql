--check the total number of rows. Expected result: 6050
SELECT COUNT(*) AS total_rows FROM fact_bookings;

--check that each booking made it to the fact table. Expected result: 0
SELECT 
    COUNT(CASE WHEN hotel_id IS NULL THEN 1 END) AS missing_hotels,
    COUNT(CASE WHEN customer_id IS NULL THEN 1 END) AS missing_customers,
    COUNT(CASE WHEN channel_id IS NULL THEN 1 END) AS missing_channels,
    COUNT(CASE WHEN salesperson_id IS NULL THEN 1 END) AS missing_salespersons
FROM fact_bookings;

--check the total core revenue. Expected result: 46778857.5
SELECT ROUND(SUM(sales), 2) AS total_core_revenue FROM fact_bookings;