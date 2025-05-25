create database hexacart;
-- importing files and 
select * from aisles;

-- import departments and check the dataset
select * from departments;

-- import  order_products_prior using infile
select * from order_products_prior;
truncate order_products_prior;
load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\order_products_prior.csv'
into table order_products_prior
fields terminated by ','
enclosed by ''
lines terminated by'\n'
ignore 1 lines;
select * from order_products_prior;

-- import order_products_train using infile
select * from order_products_train;
truncate order_products_train;
load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\order_products__train.csv'
into table order_products_train
fields terminated by ','
enclosed by ''
lines terminated by'\n'
ignore 1 lines;
select * from order_products_train;

-- import orders using infile
select * from orders;
truncate orders;
load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\orderss.csv'
into table orders
fields terminated by ','
enclosed by ''
lines terminated by'\n'
ignore 1 lines;
select * from orders;

-- import products using infile
select * from products;
truncate products;
load data infile 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\products.csv'
into table products
fields terminated by ','
enclosed by '"'
lines terminated by'\n'
ignore 1 lines;
select * from products;


select * from aisles;
select * from departments;
select * from order_products_prior;
select * from order_products_train;
select * from orders;
select * from products;


-- data cleaning to ensure data consistency and integrity
-- 1.aisles data cleaning
-- checking for duplicate.
select aisle_id, aisle, count(*) as count from aisles group by aisle_id, aisle having count > 1;

 -- cheking for null value
select * from aisles where aisle is null
or aisle_id is null;

-- 2.departments data cleaning

-- check for duplicate
select department_id, department, count(*) as count from departments group by department_id, department having count > 1;

 -- cheking for null value
select * from departments where department_id is null
or department is null;

-- 3.order_products_prior data cleaning
-- check for duplicate
select order_id, product_id, add_to_cart_order,reordered, count(*) as count from order_products_prior
group by order_id, product_id, add_to_cart_order,reordered having count > 1;

-- check for bad products and orders for order_products_prior
select * from order_products_prior where product_id not in (select product_id from products)  
or order_id not in (select order_id from orders);

-- select *  from products where product_id = 1;
-- select * from products where product_id = 34862;
-- select * from products where product_id = 38888;
-- select * from products where product_id = 12276;

-- Backup bad rows from order_products_prior
create table bad_order_products_prior as select * from order_products_prior
where product_id not in (select product_id from products) or order_id not in (select order_id from orders);

-- Delete invalid product_ids from order_products_prior
set sql_safe_updates = 0;
delete from order_products_prior
where product_id not in (select product_id from products) or order_id not in (select order_id from orders);


-- Check for any remaining invalid product_ids in prior
select * from order_products_prior
where product_id not in (select product_id from products)or order_id not in (select order_id from orders);

 -- cheking for null value
select * from order_products_prior where order_id is null or product_id is null
or add_to_cart_order is null or reordered is null;

-- 4.order_products_train data cleaning
select order_id, product_id, add_to_cart_order, reordered, count(*) as count from order_products_train
group by order_id, product_id, add_to_cart_order, reordered having count > 1;

-- check for bad product  and order for order_products_train
select * from order_products_train 
where product_id not in (select product_id from products) or order_id not in (select order_id from orders);

-- Backup bad rows from order_products_train 
create table bad_order_products_train as select * from order_products_train
where product_id not in (select product_id from products) or order_id not in (select order_id from orders);

-- Delete invalid product_ids from order_products_train
set sql_safe_updates = 0;
delete from order_products_train
where product_id not in (select product_id from products) or order_id not in (select order_id from orders);

-- Check for any remaining invalid product_ids in train
select * from order_products_train 
where product_id not in (select product_id from products)or order_id not in (select order_id from orders);

 -- cheking for null value
select * from order_products_train where order_id is null or product_id is null
or add_to_cart_order is null or reordered is null;

-- 5. orders data cleaning
-- check for duplicate
select order_id, user_id, days_since_prior_order, count(*) as count from orders
 group by order_id, user_id, days_since_prior_order having count > 1;
 
 -- cheking for null value
select * from orders where order_id is null or user_id is null or eval_set is null or order_number is null
or order_dow is null or order_hour_of_day is null or days_since_prior_order is null;

-- 6. Products data cleaning
-- check for duplicate
select product_id, product_name, aisle_id, department_id, count(*) as count from products
group by product_id, product_name, aisle_id, department_id having count > 1;

 -- cheking for null value
 select * from products where product_id is null or product_name is null
 or aisle_id is null or department_id is null;

-- checking for bad aisle
select * from products where aisle_id not in (select aisle_id from aisles);

-- checing for unavaible department
select * from products where department_id not in (select department_id from departments);

-- Add neccessary constraint
-- 1. Add Primary Key to aisles:
alter table aisles
add constraint pk_aisles primary key (aisle_id);

-- 2. Add Primary Key to departments:
alter table departments
add constraint pk_departments primary key (department_id);

-- 3. Add Primary Key to products:
alter table products
add constraint pk_products primary key (product_id);

--  Add Foreign Key to products (to aisles and departments):
alter table products
add constraint fk_products_aisle foreign key (aisle_id) references aisles(aisle_id),
add constraint fk_products_department foreign key (department_id) references departments(department_id);

-- 4. Add Primary Key to orders:
alter table orders
add constraint pk_orders primary key (order_id);

-- Add Foreign Key to order_products_prior
alter table order_products_prior
add constraint fk_opp_order foreign key (order_id)references orders(order_id),
add constraint fk_opp_product foreign key (product_id) references products(product_id);

-- Add Foreign Key to order_products_train
alter table order_products_train
add constraint fk_opt_order foreign key (order_id) references orders(order_id),
add constraint fk_opt_product foreign key (product_id) references products(product_id);

-- 1. Market Basket Analysis:
-- Analysis: Identify frequently co-occurring products in orders to improve store layout and marketing strategies.
-- Questions:

-- ●1a	What are the top 10 product pairs that are most frequently purchased together?
-- This identifies which pairs of products are most often bought in the same order
-- self join
select opp1.product_id as product_1, p1.product_name as product_name1, opp2.product_id as product_2, 1, p2.product_name as product_name2,
count(*) as pair_count from order_products_prior as opp1
join order_products_prior as opp2 on opp1.order_id = opp2.order_id and opp1.product_id < opp2.product_id  
join products as p1 on opp1.product_id = p1.product_id
join products as p2 on opp2.product_id = p2.product_id
group by opp1.product_id, opp2.product_id order by pair_count desc limit 10;

-- ●1b	What are the top 5 products that are most commonly added to the cart first?
select opt.product_id, p.product_name, COUNT(*) as first_count from order_products_train as opt
join products p on opt.product_id = p.product_id where opt.add_to_cart_order = 1
group  by opt.product_id, p.product_name order by first_count desc limit 5;

-- ●1c	How many unique products are typically included in a single order?
select avg(product_count) as avg_unique_products_per_order from (select order_id, count(distinct product_id) as product_count
from order_products_prior group by order_id) as order_product_counts;

-- 2. Customer Segmentation:
-- Analysis: Group customers based on their purchasing behavior for targeted marketing efforts.
-- Questions:
select o.user_id, count(opt.product_id) as total_products_purchased,
 case
        when count(opt.product_id) < 20 then 'Low spender'
		when count(opt.product_id) between 20 and 50 then 'Moderate spender'
		when count(opt.product_id) between 51 and 100 then 'High spender'
        else 'Top spender'
    end as spending_segment
from orders as o
join order_products_train as opt on o.order_id = opt.order_id
group by o.user_id
order by total_products_purchased desc;


-- ●2b	What are the different customer segments based on purchase frequency?
-- We’ll count how often each user orders and group them into frequency bands:

-- Add new column to orders data

alter table orders
add column simulated_order_date DATE;

-- create simulated_date
with cleaned_orders as (select order_id, user_id, order_number, coalesce(nullif(trim(days_since_prior_order),''), '0') + 0 as days_gap from orders),
cumulative_days as (select order_id, user_id, order_number,sum(days_gap) over (partition by user_id order by order_number) as total_days from cleaned_orders),
simulated_dates as (select order_id, date_add('2015-01-01', interval total_days day) as simulated_order_date from cumulative_days)
-- Update main table
update orders as o join simulated_dates as sd on o.order_id = sd.order_id
set o.simulated_order_date = sd.simulated_order_date;

 select * from orders;

create temporary table user_recency as select user_id, max(simulated_order_date) as last_order_date,
datediff(current_date, max(simulated_order_date)) as recency_days from orders group by user_id;

create temporary table user_frequency as select user_id, COUNT(order_id) as total_orders from orders group by user_id;

create temporary table user_monetary as select o.user_id, COUNT(opt.product_id) as total_products 
from orders as o join order_products_train opt on o.order_id = opt.order_id group by o.user_id;

select * from user_recency;
select * from user_frequency;
select * from user_monetary;
show tables;

select r.user_id, r.recency_days, f.total_orders, m.total_products,
 -- Recency Segment
case
        when r.recency_days <= 7 then 'Active'
        when r.recency_days <= 30 then 'Recent'
		when r.recency_days <= 90 then 'Dormant nb'
		else 'Inactive'
    end as recency_segment,

    -- Frequency Segment
    case 
        when f.total_orders = 1 then 'Rare'
        when f.total_orders between 2 and 5 then 'Occasional'
         when f.total_orders between 6 and 15 then 'Frequent'
        else 'Loyal'
    end as frequency_segment,

    -- Monetary Segment
    case 
         when m.total_products < 20 then 'Low spender'
         when m.total_products between 20 and 50 then 'Moderate spender'
         when m.total_products between 51 and 100 then 'High spender'
         else 'Top spender'
    end as spending_segment

from user_recency r
join user_frequency as f on r.user_id = f.user_id
join user_monetary as m on r.user_id = m.user_id
order by m.total_products desc;

-- ●2c	How many orders have been placed by each customer?
select user_id, count(order_id) as total_orders from orders
group by user_id order by total_orders desc;

-- 3. Seasonal Trends Analysis:
-- Analysis: Identify seasonal patterns in customer behavior and product sales.
-- Questions:
-- ●3a	What is the distribution of orders placed on different days of the week?
select order_dow, count(*) as order_count from orders
group by order_dow order by order_dow;

-- ●3b	Are there specific months with higher order volumes?
select monthname(simulated_order_date) as month_name, count(*) as total_orders from orders
where simulated_order_date is not null group by month_name order by total_orders desc;


-- 4. Customer Churn Prediction:
-- Analysis: Predict which customers are most likely to stop using the service in the near future.
-- Questions:
-- ●4a	Can we identify customers who haven't placed an order in the last 30 days?
select user_id from (select user_id, max(simulated_order_date) as last_order_date 
from orders group by user_id) as last_orders where datediff(curdate(), last_order_date) > 30;

-- 4b. What percentage of customers have churned in the past quarter?
select round(100.0 * count(*) / (select count(distinct user_id) from orders), 2) as churned_percentage
from (select user_id, max(simulated_order_date) as last_order from orders group by user_id) as last_orders
where last_order < curdate() - interval 90 day;

-- 5. Product Association Rules:
-- Analysis: Identify rules or patterns in customer behavior indicating which products are frequently bought together.
-- Questions:
-- ●5a	What are the top 5 product combinations that are most frequently purchased together?
-- This identifies which pairs of products are most often bought in the same order
select opp1.product_id as product_1, opp2.product_id as product_2, count(*) as frequency
from order_products_prior as opp1 join order_products_prior as opp2
on opp1.order_id = opp2.order_id and opp1.product_id < opp2.product_id
group by opp1.product_id, opp2.product_id order by frequency desc limit 5;


-- ●5b	Can we find products that are often bought together on weekends vs. weekdays?
select opp1.product_id as product_1, opp1.product_id as product_2, o.order_dow, count(*) as frequency
from order_products_prior as opp1 join order_products_prior as opp2
join orders as o on opp1.order_id = o.order_id
where o.order_dow in (0, 6)
group by opp1.product_id, opp2.product_id, o.order_dow order by frequency desc limit 10;



























































































































































































































































































































































































































































