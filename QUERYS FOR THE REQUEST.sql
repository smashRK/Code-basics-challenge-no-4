
select * from dim_product
where division='N & S'
group by division, segment, category;

#request_one
use gdb023;
select distinct market, customer, region
From dim_customer
where customer = 'Atliq Exclusive' and region = 'APAC';

-- request two
desc dim_product;

with product_count_2020 as (
select count(distinct product_code) as product_2020
from fact_sales_monthly where fiscal_year = 2020),
product_count_2021 as (
select count(distinct product_code) as product_2021
from fact_sales_monthly where fiscal_year = 2021),
percentage as (select
(((pc21.product_2021 - pc20.product_2020) / pc20.product_2020) * 100) as percentage_chg
from product_count_2020 pc20, product_count_2021 pc21)

select pc20.product_2020 as unique_products_2020, pc21.product_2021 as unique_products_2021, p.percentage_chg
from product_count_2020 pc20, product_count_2021 pc21, percentage p;

-- request three

select segment, count(distinct product_code) as product_count
from dim_product group by segment order by product_count desc;

-- request four

with prod_2020 as (select dp.segment, dp.product_code, count(distinct dp.product_code) as product_count_2020
from dim_product dp join fact_sales_monthly on dp.product_code = fact_sales_monthly.product_code
where fiscal_year = 2020 group by segment),
prod_2021 as (select dp.segment, dp.product_code, count(distinct dp.product_code) as product_count_2021
from dim_product dp join fact_sales_monthly on dp.product_code = fact_sales_monthly.product_code
where fiscal_year = 2021 group by segment)

select pc20.segment, pc20.product_count_2020, pc21.product_count_2021,
(pc21.product_count_2021 - pc20.product_count_2020) as difference
from prod_2020 pc20 join prod_2021 pc21 using(segment) order by difference desc;

-- request 5

select product_code, dim_product.product, manufacturing_cost
from 
fact_manufacturing_cost join dim_product using(product_code) 
where manufacturing_cost in(
select max(manufacturing_cost) from fact_manufacturing_cost
union 
select min(manufacturing_cost) from fact_manufacturing_cost)
order by manufacturing_cost desc;

-- request 6
use gdb023;

select F.customer_code, dim_customer.customer, f.pre_invoice_discount_pct*100 as average_discount_percentage 
from fact_pre_invoice_deductions f join dim_customer using(customer_code) 
where f.fiscal_year = 2021 and dim_customer.market= 'india'
group by F.customer_code, dim_customer.customer
order by f.pre_invoice_discount_pct*100 desc limit 5;

-- request 7
select month(f.date) as Month, year(f.date) as Year, round(sum(fg.gross_price * f.sold_quantity)) as Gross_sales_Amount 
from fact_gross_price fg join fact_sales_monthly f using(product_code) join dim_customer d using(customer_code) 
where d.customer = 'Atliq Exclusive' group by year(f.date), month(f.date) 
order by  year(f.date), month(f.date);

-- request 8
select quarter(date) as Quater, sum(sold_quantity) as total_sold_quantity from fact_sales_monthly 
where year(date) = 2020 group by quarter(date) 
order by sum(sold_quantity) desc;

-- request 9
with channel_gross as
(select d.channel, round(sum(fg.gross_price * f.sold_quantity)) as gross_sales_mln
from fact_gross_price fg join fact_sales_monthly f using(product_code) join dim_customer d using(customer_code) 
where year(f.date) = 2021 
group by d.channel)

select channel, gross_sales_mln, round((gross_sales_mln*100/sum(gross_sales_mln) over()),1) as percentage
from channel_gross group by channel
order by percentage desc;

-- request 10

with top_3 as( 
select d.division, d.product_code, d.product, sum(fs.sold_quantity) as total_sold_quantity,
dense_rank() 
OVER ( partition by d.division order by sum(fs.sold_quantity) desc ) as Rank_order
from fact_sales_monthly fs join dim_product d
using(product_code) where year( fs.date ) = 2021 
group by d.division, d.product_code, d.product)

select * from top_3 where Rank_order < 4