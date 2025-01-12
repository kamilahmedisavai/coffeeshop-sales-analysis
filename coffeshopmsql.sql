Use CoffeeShopSaleDb;
go

select *from Coffee_Shop_Sales;

EXEC sp_columns Coffee_Shop_Sales;


ALTER TABLE Coffee_Shop_Sales
ADD total_sales AS (transaction_qty * unit_price);


--Total Sales Analysis


WITH MonthlySales AS (
    SELECT 
        YEAR(transaction_date) AS Year,
        MONTH(transaction_date) AS Month,
        SUM(transaction_qty * unit_price) AS Total_Sales
    FROM 
        Coffee_Shop_Sales
    GROUP BY 
        YEAR(transaction_date), MONTH(transaction_date)
)
, MonthlySalesWithMoM AS (
    SELECT 
        Year,
        Month,
        Total_Sales,
        LAG(Total_Sales, 1) OVER (ORDER BY Year, Month) AS Prev_Month_Sales
    FROM 
        MonthlySales
)
SELECT 
    Year,
    Month,
    Total_Sales,
    Prev_Month_Sales,
    (Total_Sales - Prev_Month_Sales) AS Sales_Difference,
    (Total_Sales - Prev_Month_Sales) * 100.0 / NULLIF(Prev_Month_Sales, 0) AS MoM_Percentage_Change
FROM 
    MonthlySalesWithMoM
ORDER BY 
    Year, Month;



--2: Total Orders Analysis

WITH MonthlyOrders AS (
    SELECT 
        YEAR(transaction_date) AS Year,
        MONTH(transaction_date) AS Month,
        COUNT(transaction_id) AS Total_Orders
    FROM 
         Coffee_Shop_Sales
    GROUP BY 
        YEAR(transaction_date), MONTH(transaction_date)
)
, MonthlyOrdersWithMoM AS (
    SELECT 
        Year,
        Month,
        Total_Orders,
        LAG(Total_Orders, 1) OVER (ORDER BY Year, Month) AS Prev_Month_Orders
    FROM 
        MonthlyOrders
)
SELECT 
    Year,
    Month,
    Total_Orders,
    Prev_Month_Orders,
    (Total_Orders - Prev_Month_Orders) AS Orders_Difference,
    (Total_Orders - Prev_Month_Orders) * 100.0 / NULLIF(Prev_Month_Orders, 0) AS MoM_Percentage_Change
FROM 
    MonthlyOrdersWithMoM
ORDER BY 
    Year, Month;



--3: Total Quantity Sold Analysis

WITH MonthlyQuantity AS (
    SELECT 
        YEAR(transaction_date) AS Year,
        MONTH(transaction_date) AS Month,
        SUM(transaction_qty) AS Total_Quantity_Sold
    FROM 
        Coffee_Shop_Sales
    GROUP BY 
        YEAR(transaction_date), MONTH(transaction_date)
)
, MonthlyQuantityWithMoM AS (
    SELECT 
        Year,
        Month,
        Total_Quantity_Sold,
        LAG(Total_Quantity_Sold, 1) OVER (ORDER BY Year, Month) AS Prev_Month_Quantity
    FROM 
        MonthlyQuantity
)
SELECT 
    Year,
    Month,
    Total_Quantity_Sold,
    Prev_Month_Quantity,
    (Total_Quantity_Sold - Prev_Month_Quantity) AS Quantity_Difference,
    (Total_Quantity_Sold - Prev_Month_Quantity) * 100.0 / NULLIF(Prev_Month_Quantity, 0) AS MoM_Percentage_Change
FROM 
    MonthlyQuantityWithMoM
ORDER BY 
    Year, Month;

-- calender heat map 
SELECT 
    -- Extract Year, Month, Day from transaction_date
    YEAR(transaction_date) AS Year,
    MONTH(transaction_date) AS Month,
    DAY(transaction_date) AS Day,
    
    -- Total sales for the day (transaction_qty * unit_price)
    SUM(transaction_qty * unit_price) AS Total_Sales,
    
    -- Total quantity sold for the day
    SUM(transaction_qty) AS Total_Quantity_Sold,
    
    -- Total orders for the day (count of distinct transaction IDs)
    COUNT(DISTINCT transaction_id) AS Total_Orders
FROM 
    Coffee_Shop_Sales
WHERE
    -- Optional: filter by a specific date range (e.g., last 12 months)
    transaction_date >= '2023-03-27' AND transaction_date <= '2023-05-30'
GROUP BY
    YEAR(transaction_date),
    MONTH(transaction_date),
    DAY(transaction_date)
ORDER BY
    Year,
    Month,
    Day;



	--2. Sales Analysis by Weekdays and Weekends

	SELECT 
    -- Categorize days into Weekdays and Weekends
    CASE 
        WHEN DATEPART(WEEKDAY, transaction_date) BETWEEN 2 AND 6 THEN 'Weekday'  -- Monday (2) to Friday (6)
        WHEN DATEPART(WEEKDAY, transaction_date) IN (1, 7) THEN 'Weekend'       -- Saturday (7) and Sunday (1)
    END AS Weekday_Weekend,
    
    -- Total sales for Weekdays and Weekends
    SUM(transaction_qty * unit_price) AS Total_Sales,
    
    -- Total quantity sold for Weekdays and Weekends
    SUM(transaction_qty) AS Total_Quantity_Sold,
    
    -- Total number of orders (distinct transaction_id)
    COUNT(DISTINCT transaction_id) AS Total_Orders
FROM 
	Coffee_Shop_Sales
WHERE
    -- Optional: filter by a specific date range (e.g., last 12 months)
    transaction_date >= '2023-05-12' AND transaction_date <= '2023-05-16'
GROUP BY
    CASE 
        WHEN DATEPART(WEEKDAY, transaction_date) BETWEEN 2 AND 6 THEN 'Weekday'
        WHEN DATEPART(WEEKDAY, transaction_date) IN (1, 7) THEN 'Weekend'
    END
ORDER BY
    Weekday_Weekend;


	Select *from Coffee_Shop_Sales;
--3. Sales Analysis by Store Location.


SELECT 
    store_location,
    
    -- Total sales for each store location
    SUM(transaction_qty * unit_price) AS Total_Sales,
    
    -- Total quantity sold for each store location
    SUM(transaction_qty) AS Total_Quantity_Sold,
    
    -- Total number of orders (distinct transaction IDs) for each store location
    COUNT(DISTINCT transaction_id) AS Total_Orders
FROM 
    Coffee_Shop_Sales
WHERE
    -- Optional: filter by a specific date range (e.g., last 12 months)
    transaction_date >= '2023-05-01' AND transaction_date <= '2023-05-31'
GROUP BY
    store_location
ORDER BY
    Total_Sales DESC;  -- Sort by total sales in descending order


--4. Daily Sales Analysis with Average Line


WITH DailySales AS (
    -- Step 1: Calculate total sales for each day
    SELECT 
        transaction_date,
        SUM(transaction_qty * unit_price) AS Total_Sales
    FROM 
        Coffee_Shop_Sales
    WHERE 
        -- Optional: filter by a specific date range
        transaction_date >= '2023-05-01' AND transaction_date <= '2023-12-31'
    GROUP BY 
        transaction_date
),
AverageSales AS (
    -- Step 2: Calculate the overall average daily sales
    SELECT 
        AVG(Total_Sales) AS Average_Daily_Sales
    FROM 
        DailySales
)
-- Step 3: Combine daily sales with the average
SELECT 
    DS.transaction_date,
    DS.Total_Sales,
    ASales.Average_Daily_Sales
FROM 
    DailySales AS DS
CROSS JOIN 
    AverageSales AS ASales
ORDER BY 
    DS.transaction_date;



--5. Sales Analysis by Product Category

SELECT 
    product_category,

    -- Total sales for each product category
    SUM(transaction_qty * unit_price) AS Total_Sales,

    -- Total quantity sold for each product category
    SUM(transaction_qty) AS Total_Quantity_Sold,

    -- Total number of orders (distinct transaction IDs) for each product category
    COUNT(DISTINCT transaction_id) AS Total_Orders
FROM 
    Coffee_Shop_Sales
WHERE
    -- Optional: filter by a specific date range
    transaction_date >= '2023-05-01' AND transaction_date <= '2023-05-31'
GROUP BY
    product_category
ORDER BY
    Total_Sales DESC;  -- Sort by total sales in descending order


--6. Top 10 Products by Sales

SELECT 
    product_id,
    product_detail,
    
    -- Total sales for each product
    SUM(transaction_qty * unit_price) AS Total_Sales,

    -- Total quantity sold for each product
    SUM(transaction_qty) AS Total_Quantity_Sold,

    -- Total number of orders (distinct transaction IDs) for each product
    COUNT(DISTINCT transaction_id) AS Total_Orders
FROM 
    Coffee_Shop_Sales
WHERE
    -- Optional: filter by a specific date range
    transaction_date >= '2023-05-01' AND transaction_date <= '2023-05-31'
GROUP BY
    product_id, 
    product_detail
ORDER BY
    Total_Sales DESC  -- Sort by total sales in descending order
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; -- Fetch the top 10 products



----


SELECT 
    product_type,

    -- Total sales for each product type
    SUM(transaction_qty * unit_price) AS Total_Sales,

    -- Total quantity sold for each product type
    SUM(transaction_qty) AS Total_Quantity_Sold,

    -- Total number of orders (distinct transaction IDs) for each product type
    COUNT(DISTINCT transaction_id) AS Total_Orders
FROM 
    Coffee_Shop_Sales
WHERE
    -- Optional: filter by a specific date range
    transaction_date >= '2023-05-01' AND transaction_date <= '2023-05-31'
GROUP BY
    product_type
ORDER BY
    Total_Sales DESC;  -- Sort by total sales in descending order


Select *from Coffee_Shop_Sales;
----

SELECT 
    product_type,

    -- Total sales for each product type under the "Coffee" category
    SUM(transaction_qty * unit_price) AS Total_Sales,

    -- Total quantity sold for each product type under the "Coffee" category
    SUM(transaction_qty) AS Total_Quantity_Sold,

    -- Total number of orders (distinct transaction IDs) for each product type under the "Coffee" category
    COUNT(DISTINCT transaction_id) AS Total_Orders
FROM 
    Coffee_Shop_Sales
WHERE
    product_category = 'Coffee'  -- Filter for the "Coffee" category
    AND transaction_date >= '2023-05-01'  -- Optional: filter for a specific date range
    AND transaction_date <= '2023-05-31'
GROUP BY
    product_type
ORDER BY
    Total_Sales DESC;  -- Sort by total sales in descending order


--7. Sales Analysis by Days and Hours

SELECT 
    DATENAME(WEEKDAY, transaction_date) AS Day_of_Week, -- Name of the day (e.g., Monday, Tuesday)
    DATEPART(HOUR, transaction_time) AS Hour_of_Day,    -- Extract the hour from the transaction time

    -- Total sales for each day and hour
    SUM(transaction_qty * unit_price) AS Total_Sales,

    -- Total quantity sold for each day and hour
    SUM(transaction_qty) AS Total_Quantity_Sold,

    -- Total number of orders (distinct transaction IDs) for each day and hour
    COUNT(DISTINCT transaction_id) AS Total_Orders
FROM 
    Coffee_Shop_Sales
WHERE
    -- Optional: filter for a specific date range
    transaction_date = '2023-05-14' 
GROUP BY
    DATENAME(WEEKDAY, transaction_date),
    DATEPART(WEEKDAY, transaction_date),  -- Ensure correct weekday sorting
    DATEPART(HOUR, transaction_time)
ORDER BY
    DATEPART(WEEKDAY, transaction_date),  -- Sort by weekday (e.g., Monday, Tuesday, etc.)
    Hour_of_Day;                          -- Then sort by hour of day
