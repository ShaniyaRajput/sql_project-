/* Q1) Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.
*/

select  count(distinct(market))
from dim_customer
where region = 'APAC';   

/* Q2) What is the percentage of unique product increase in 2021 vs. 2020? */

with per as 
(
select  count(distinct(case when fiscal_year = 2021 then product_code end)) as 2021_pro,  
        count(distinct(case when fiscal_year = 2020 then product_code end)) as 2020_pro
from fact_gross_price
)
select  2021_pro, 
        2020_pro,
        ((2021_pro - 2020_pro)/ 2020_pro)*100  as Percentage_change
from per;

/* Q3) Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. */

select  segment, 
        count(distinct(product_code)) as total_count
from dim_product
group by 1
order by 2 desc; 

/* Q4) Which segment had the most increase in unique products in
2021 vs 2020? */

with cte1 as (
select  p.product_code,
        p.segment, 
        f.fiscal_year
from dim_product as p
inner join fact_gross_price as f
on p.product_code = f.product_code
),
cte2 as(
select  segment,
        count(case when fiscal_year = 2020 then product_code end) as pro_2020,
        count(case when fiscal_year = 2021 then product_code end) as pro_2021
from cte1
group by 1)
select  *,
        100*((pro_2021 - pro_2020)/pro_2020) as delta
from cte2;

/* Q 5) Get the products that have the highest and lowest manufacturing costs */

select  p.product, 
        p.product_code, 
        m.manufacturing_cost
from dim_product as p
inner join fact_manufacturing_cost as m
on p.product_code = m.product_code
where m.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost) 
union all
select  p.product, 
        p.product_code, 
        m.manufacturing_cost
from dim_product as p
inner join fact_manufacturing_cost as m
on p.product_code = m.product_code
where m.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost) ;

/* Q 6) Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market */

select  c.customer_code,
        c.customer, 
        avg(d.pre_invoice_discount_pct) as avg_dis
from dim_customer as c
inner join fact_pre_invoice_deductions as d
on c.customer_code = d.customer_code
where market = 'India' and fiscal_year = 2021
group by 1,2 
order by 3 desc
limit 5;

/* Q 7) Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions. */

WITH quarters AS (
  SELECT *,
         CASE
           WHEN MONTH(date) IN (9, 10, 11) THEN 'Q1'
           WHEN MONTH(date) IN (12, 1, 2) THEN 'Q2'
           WHEN MONTH(date) IN (3, 4, 5) THEN 'Q3'
           WHEN MONTH(date) IN (6, 7, 8) THEN 'Q4'
         END AS Quarter
  FROM fact_sales_monthly
  WHERE fiscal_year = 2020
)

SELECT  Quarter, 
        SUM(sold_quantity) AS total_sold_quantity
FROM quarters
GROUP BY 1
ORDER BY 2 DESC;

/* Q 8) In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity */

select  quarter(date) as Quater, 
        sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year = 2020
group by 1
order by 2 desc;

/* Q 9) Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? */

with cte1 as (
SELECT  s.customer_code,
        c.`channel`,
        (s.sold_quantity * g.gross_price) as ttl_sales
FROM gdb023.fact_sales_monthly as s
inner join fact_gross_price as g
on s.product_code = g.product_code and s.fiscal_year = g.fiscal_year 
inner join gdb023.dim_customer as c
on s.customer_code =  c.customer_code
where g.fiscal_year = 2021),
cte2 as (
select  `channel`, 
         sum(ttl_sales) as gross_sales_mln
from cte1
group by 1
order by 2)
select  `channel`, 
         gross_sales_mln,
         gross_sales_mln/(select sum(gross_sales_mln) from cte2)* 100 as Pct_of_ttl
from cte2;

/* Q 10) Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021?  */

with cte as (
SELECT  p.division,
        p.product_code, 
        sum(s.sold_quantity),
        dense_rank() over(partition by p.division order by sum(s.sold_quantity) desc) as Top_sold_items
FROM gdb023.dim_product as p
inner join fact_sales_monthly as s 
on p.product_code = s.product_code 
where s.fiscal_year = 2021
group by 1,2)
 
select  *
from cte
where Top_sold_items <= 3 ;
