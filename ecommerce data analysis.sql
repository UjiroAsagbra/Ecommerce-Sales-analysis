--inspecting Data
SELECT *
FROM ['original data$']
--order by InvoiceDate




--Checking Unique Values
SELECT DISTINCT customerid FROM ['original data$']
SELECT DISTINCT StockCode FROM ['original data$']
SELECT DISTINCT Country FROM ['original data$']
SELECT DISTINCT InvoiceNo FROM ['original data$']
SELECT DISTINCT YEAR(invoicedate) FROM ['original data$']
SELECT DISTINCT MONTH(invoicedate) FROM ['original data$']

--ANALYSIS

--TOTAL SALES
SELECT *, (quantity * [ UnitPrice ]) Totalsales 
FROM ['original data$']
--WHERE CustomerID IS NOT NULL
ORDER BY InvoiceDate, CustomerID

--TOTAL SALES BY COUNTRY
SELECT country, SUM(quantity * [ UnitPrice ]) Revenue
FROM ['original data$']
GROUP BY Country
ORDER BY 2 DESC

--TOTAL SALES BY YEAR
SELECT YEAR(invoicedate) [Year], SUM(quantity * [ UnitPrice ]) Revenue
FROM ['original data$']
GROUP BY YEAR(invoicedate)
ORDER BY 1


-- TOTAL SALES BY MONTH
SELECT MONTH(invoicedate) [month], SUM(quantity * [ UnitPrice ]) Revenue--, COUNT(InvoiceNo) Frequency
FROM ['original data$']
WHERE YEAR(invoicedate) = 2011
GROUP BY MONTH(invoicedate)
ORDER BY [MONTH]

--BEST MONTH FOR SALES
SELECT TOP 1 MONTH(invoicedate) [month], SUM(quantity * [ UnitPrice ]) Revenue, COUNT(InvoiceNo) SalesFrequency
FROM ['original data$']
WHERE YEAR(invoicedate) = 2011
GROUP BY MONTH(invoicedate)
ORDER BY SalesFrequency DESC

--BEST SELLING PRODUCTS IN NOVEMBER 2011

--BY TOTAL SALES
SELECT TOP 5(StockCode), COUNT(StockCode) SalesFrequency
FROM ['original data$']
WHERE YEAR(invoicedate) = 2011 AND MONTH(invoicedate) = 11
GROUP BY StockCode
ORDER BY SalesFrequency DESC

--BY REVENUE
SELECT TOP 5(StockCode), SUM(quantity * [ UnitPrice ]) Revenue
FROM ['original data$']
WHERE YEAR(invoicedate) = 2011 AND MONTH(invoicedate) = 11
GROUP BY StockCode
ORDER BY Revenue DESC

--Which is the best selling product in each country?
SELECT Country,MAX(StockCode) Item, COUNT(StockCode) SalesFrequency
FROM ['original data$']
WHERE YEAR(invoicedate) = 2011 AND MONTH(invoicedate) = 11
GROUP BY Country

---CUSTOMER RFM analysis 

--temp table and CTE
DROP TABLE IF EXISTS #rfm
;WITH rfm AS 
(
	SELECT 
		customerid,
		SUM(quantity * [ UnitPrice ]) Spent,
		AVG(quantity * [ UnitPrice ]) Average_spent ,
		COUNT(invoiceno) Frequency,
		MAX(invoicedate) Last_order_date,
		(SELECT MAX(invoicedate) FROM ['original data$']) max_order_date,
		DATEDIFF(DD,MAX(invoicedate), (SELECT MAX(invoicedate) FROM ['original data$'])) Recency
FROM ['original data$']
GROUP BY CustomerID
),
rfm_calc AS
(
	SELECT *,
		NTILE(4) OVER (ORDER BY recency) rfm_recency,
		NTILE(4) OVER (ORDER BY frequency) rfm_frequency,
		NTILE(4) OVER (ORDER BY spent) rfm_spent
	FROM rfm r
)
SELECT 
	c.*, rfm_recency+rfm_frequency+rfm_spent AS rfm_cell,
	CAST(rfm_recency AS varchar) + CAST(rfm_frequency AS varchar) + CAST(rfm_spent AS varchar)rfm_cell_string
INTO #rfm
FROM rfm_calc c;

--most recent is 1, least recent is 4
--most frequent buyers are 4 n less frequent are 1
--more spend  is 4
--select distinct rfm_cell_string from #rfm, used to find out the possible combinations

--TOTAL CUSTOMERS LOST PER MONTH
WITH CustomerStatus AS
(
	SELECT CustomerID,rfm_recency,rfm_frequency, rfm_spent,
		CASE
			WHEN rfm_cell_string IN (411,424,312,413,414,313) THEN 'New Customer' --bought recently, and frequency is low
			WHEN rfm_cell_string IN (422,324,421,412,222,321,314,331,423,323,311,322,432) THEN 'Active Customer' --bought recently but has low frequency
			WHEN rfm_cell_string IN (433,443,343,334,444,344,333,341,431,332,342,442,434) THEN 'Loyal customer' --bought recently, buys frquently and spends alot
			WHEN rfm_cell_string IN (111,221,234,124,113,123,114,214,112,131,212,121,132,133,211,213,142,122) THEN 'Lost Customer' --hasnt bought recently and has low frequency
			WHEN rfm_cell_string IN (134,143,233,144,243,141,244,231,223,242,224,232) THEN 'Slipping Away' --hasnt bought recently but buy often
			END rfm_segment
		FROM #rfm

),
LostCustomer AS
(
	SELECT month(org.InvoiceDate) [Month],count(*) LostCustomer 
	FROM CustomerStatus cs
	JOIN ['original data$'] org
	On org.CustomerID = cs.CustomerID
	WHERE  rfm_segment = 'Lost Customer' AND YEAR(org.InvoiceDate) = 2011
	GROUP BY month(org.InvoiceDate)
)
SELECT LostCustomer,
		CASE 
			WHEN Month = 1 THEN 'January'
			WHEN Month = 2 THEN 'Feburary'
			WHEN Month = 3 THEN 'March'
			WHEN Month = 4 THEN 'April'
			WHEN Month = 5 THEN 'May'
			WHEN Month = 6 THEN 'June'
			WHEN Month = 7 THEN 'July'
			WHEN Month = 8 THEN 'August'
			WHEN Month = 9 THEN 'September'
			WHEN Month = 10 THEN 'October'
			WHEN Month = 11 THEN 'November'
			WHEN Month = 12 THEN 'December'
		END Month
FROM LostCustomer
ORDER BY month

--TOTAL NEW CUSTOMERS PER MONTH
WITH CustomerStatus AS
(
	SELECT CustomerID,rfm_recency,rfm_frequency, rfm_spent,
		CASE
			WHEN rfm_cell_string IN (411,424,312,413,414,313) THEN 'New Customer' --bought recently, and frequency is low
			WHEN rfm_cell_string IN (422,324,421,412,222,321,314,331,423,323,311,322,432) THEN 'Active Customer' --bought recently but has low frequency
			WHEN rfm_cell_string IN (433,443,343,334,444,344,333,341,431,332,342,442,434) THEN 'Loyal customer' --bought recently, buys frquently and spends alot
			WHEN rfm_cell_string IN (111,221,234,124,113,123,114,214,112,131,212,121,132,133,211,213,142,122) THEN 'Lost Customer' --hasnt bought recently and has low frequency
			WHEN rfm_cell_string IN (134,143,233,144,243,141,244,231,223,242,224,232) THEN 'Slipping Away' --hasnt bought recently but buy often
			END rfm_segment
		FROM #rfm

),
NewCustomer AS
(
	SELECT month(org.InvoiceDate) [Month],count(*) NEWCustomer 
	FROM CustomerStatus cs
	JOIN ['original data$'] org
	On org.CustomerID = cs.CustomerID
	WHERE  rfm_segment = 'New Customer' AND YEAR(org.InvoiceDate) = 2011
	GROUP BY month(org.InvoiceDate)
)
SELECT NewCustomer,
		CASE 
			WHEN Month = 1 THEN 'January'
			WHEN Month = 2 THEN 'Feburary'
			WHEN Month = 3 THEN 'March'
			WHEN Month = 4 THEN 'April'
			WHEN Month = 5 THEN 'May'
			WHEN Month = 6 THEN 'June'
			WHEN Month = 7 THEN 'July'
			WHEN Month = 8 THEN 'August'
			WHEN Month = 9 THEN 'September'
			WHEN Month = 10 THEN 'October'
			WHEN Month = 11 THEN 'November'
			WHEN Month = 12 THEN 'December'
		END Month
FROM NewCustomer
ORDER BY month

