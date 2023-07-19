-- Inspecting Data

SELECT *
FROM sales_data_sample

-- Checking Unique Values

-- Good data to plot
SELECT DISTINCT STATUS 
FROM sales_data_sample

SELECT DISTINCT YEAR_ID
FROM sales_data_sample

-- Good data to plot
SELECT DISTINCT PRODUCTLINE
FROM sales_data_sample
-- Good data to plot
SELECT DISTINCT COUNTRY
FROM sales_data_sample
-- Good data to plot
SELECT DISTINCT DEALSIZE
FROM sales_data_sample
-- Good data to plot
SELECT DISTINCT TERRITORY
FROM sales_data_sample

-- ANALYSIS
-- Let's start by grouping sales by productline

-- Which prouctive sales the most

SELECT PRODUCTLINE, SUM(sales) AS REVENUE
FROM sales_data_sample
GROUP BY PRODUCTLINE
ORDER BY REVENUE DESC

-- Which year made the most 

SELECT YEAR_ID, SUM(sales) AS REVENUE
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY REVENUE DESC

-- SIDE NOTE
-- operated only for 5 months in 2005
SELECT DISTINCT MONTH_ID
FROM sales_data_sample
WHERE YEAR_ID = 2005

-- Which dealsize generated the most revenue

SELECT DEALSIZE, SUM(sales) AS REVENUE
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY REVENUE DESC

-- What was the best month for sales in a specific year? How much was earned that month?
-- In 2003 Novemeber had 296 orders with a total revenue of 1,029,837.66

SELECT MONTH_ID, SUM(SALES) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM sales_data_sample
WHERE YEAR_ID = 2003 -- change year to see total revenue for best month
GROUP BY MONTH_ID
ORDER BY REVENUE DESC

-- November seems to be the month, what product do they sell in November? +
-- Class Car

SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) AS REVENUE, COUNT(ORDERNUMBER) AS FREQUENCY
FROM sales_data_sample
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID, PRODUCTLINE
ORDER BY REVENUE DESC

-- Who is our best customer? RFM Analysis (Recency-Frequency-Monetary)
-- Laste order date, Count of total orders, total spend

DROP TABLE IF EXISTS #rfm
;with rfm as
(
		select
			CUSTOMERNAME,
			sum(sales) as Monetary_Value,
			avg(sales) as Avg_Monetary_Value,
			count(ORDERNUMBER)  as Frequency,
			max(ORDERDATE) as Last_Order_Date,
			(select max(ORDERDATE) from sales_data_sample) as Max_Order_Date,
			DATEDIFF(DD,  MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample) ) as Recency
		from sales_data_sample
		group by CUSTOMERNAME
),
rfm_calc as
(

		select r.*,
			NTILE (4) OVER (order by Recency desc) rfm_Recency,
			NTILE (4) OVER (order by Frequency ) rfm_Frequency,
			NTILE (4) OVER (order by Monetary_Value ) rfm_Monetary
		from rfm r
)
select
	c.*, rfm_Recency+ rfm_Frequency+ rfm_Monetary as rfm_Cell,
	cast(rfm_Recency as varchar) + cast(rfm_Frequency as varchar) + cast(rfm_Monetary as varchar) rfm_Cell_String
into #rfm
from rfm_calc c

select CUSTOMERNAME , rfm_Recency, rfm_Frequency, rfm_Monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm

--What products are most often sold together?

SELECT ORDERNUMBER, COUNT(*) AS RN
FROM sales_data_sample
WHERE STATUS = 'Shipped'
GROUP BY ORDERNUMBER

--Data for order number 10411
SELECT *
FROM sales_data_sample
WHERE ORDERNUMBER = 10411

--Which Products are sold together

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from sales_data_sample p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3 -- only 13 products sold together
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') Product_Codes

from sales_data_sample s
order by 2 desc