CREATE DATABASE RetailSalesData;
Use RetailSalesData;

CREATE TABLE Sales_Data_Transactions(
customer_id VARCHAR(255),
trans_date VARCHAR(255),
tran_amount INT);

CREATE TABLE Sales_Data_Response(
customer_id VARCHAR(255),
response INT);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Retail_Data_Transactions.csv'
INTO TABLE Sales_Data_Transactions
FIELDS terminated by ','
LINES terminated by '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Retail_Data_Response.csv'
INTO TABLE Sales_Data_Response
FIELDS terminated by ','
LINES terminated by '\n'
IGNORE 1 ROWS;

Select * From Sales_Data_Transactions;

Describe Sales_Data_Transactions;

-- Changing Datatype of Trans_date column to date
-- Adding a new DATE column
ALTER TABLE Sales_Data_Transactions
ADD COLUMN trans_date_new DATE;

-- Converting text to date
UPDATE Sales_Data_Transactions
SET trans_date_new = STR_TO_DATE(trans_date, '%d-%b-%y');

-- Checking old and new dates
SELECT trans_date AS old_txt,
trans_date_new  AS new_date
FROM   Sales_Data_Transactions
LIMIT  10;

-- Droping old column and Making the new column official one
ALTER TABLE Sales_Data_Transactions
DROP COLUMN trans_date,
CHANGE COLUMN trans_date_new trans_date DATE NOT NULL;

-- Basic Analysis
-- Row count & min / max dates
SELECT COUNT(*) AS total_row,
MIN(trans_date) AS first_txn,
MAX(trans_date) AS last_txn
FROM Sales_Data_Transactions;

-- Null / negative amounts
SELECT COUNT(*) AS null_values
FROM Sales_Data_Transactions
WHERE tran_amount IS NULL
OR tran_amount < 0;

-- Aggregate revenue & order metrics
-- Total Revenue
SELECT SUM(tran_amount) AS total_revenue
FROM Sales_Data_Transactions;

-- Total Revenue and Order By Month & Year
SELECT YEAR(trans_date)  AS yr,  
       MONTH(trans_date) AS mon,  
       COUNT(*)          AS orders,  
       SUM(tran_amount)  AS revenue,
       AVG(tran_amount)  AS avg_order_value
FROM   Sales_Data_Transactions  
GROUP  BY yr, mon  
ORDER  BY yr, mon;  

-- Customer-level KPIs
-- Metrics per customer
SELECT customer_id,
COUNT(*) AS orders,
MIN(trans_date) AS first_order,
MAX(trans_date) AS last_order,
SUM(tran_amount) AS customer_revenue,
AVG(tran_amount) AS avg_order_value
FROM  Sales_Data_Transactions
GROUP BY customer_id;

-- Top 10 customers by revenue
SELECT customer_id,
SUM(tran_amount) AS revenue
FROM Sales_Data_Transactions
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 10;

--  Merging Response Table And Creating View
CREATE OR REPLACE VIEW v_sales_with_response AS
SELECT t.customer_id,
t.trans_date,
t.tran_amount,
r.response
FROM Sales_Data_Transactions  AS t
LEFT JOIN Sales_Data_Response AS r
ON r.customer_id = t.customer_id;

SELECT * FROM v_sales_with_response;

-- Total Count Check
SELECT
COUNT(*) AS total_row,
SUM(response = 1) AS responses,
SUM(response = 0 OR response IS NULL) AS non_responses,
COUNT(DISTINCT customer_id) AS customers
FROM v_sales_with_response;

-- How many customers responded?
SELECT response,
COUNT(DISTINCT customer_id) AS customers,
COUNT(*) AS transactions,
SUM(tran_amount) AS revenue,
AVG(tran_amount) AS avg_order_value
FROM v_sales_with_response
GROUP BY response;

-- Year-by-year revenue split
SELECT
YEAR(trans_date) AS yr,
SUM(CASE WHEN response = 1 THEN tran_amount END) AS rev_responder,
SUM(CASE WHEN response = 0 THEN tran_amount END) AS rev_nonresponder
FROM v_sales_with_response
GROUP BY yr
ORDER BY yr;

-- Recency/Frequency/Monetary (RFM) comparison
WITH rfm AS (
SELECT customer_id,
response,
MAX(trans_date) AS last_txn,
COUNT(*) AS freq,
SUM(tran_amount) AS monetary
FROM v_sales_with_response
GROUP BY customer_id, response
)
SELECT response,
AVG(DATEDIFF(CURDATE(), last_txn)) AS avg_recency_days,
AVG(freq) AS avg_frequency, 
AVG(monetary) AS avg_monetary
FROM rfm
GROUP BY response;