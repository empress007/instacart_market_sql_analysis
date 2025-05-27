🛒 Instacart Market Basket Analysis

# ![1_DHfQvlMVBaJCHpYmj1kmCw](https://github.com/user-attachments/assets/f9dcef96-4a10-4b54-b41b-f777143c4e76)

## 💻 Table of Contents
- [Introduction](#introduction)
- [Dataset Overview](#dataset-overview)
- [Project Objectives](#project-objectives)
- [Data Cleaning](#data-cleaning)
- [Data Exploration and Insights](#data-exploration-and-insights)
- [Recommendation](#recommendation)
- [Conclusion](#conclusion)
- [Tech Stack](#tech-stack)

---

## 📌 Introduction
The Instacart Market Basket Analysis project aims to explore and analyze customer shopping behavior using transactional data from the Instacart platform. 
This dataset provides a rich source of information that can be used to derive valuable insights for optimizing operations and enhancing customer experiences.


---

## 📊 Dataset Overview

The dataset consists of multiple CSV files that track orders, products, user behavior, and departments:

| File | Description |
|------|-------------|
| `aisles.csv` | Contains information about different product categories (aisles). |
| `departments.csv` | Provides details about various departments within the store. |
| `orders.csv` | Contains details about products in the training set of customer orders, Order data including user ID, time of order, and order frequency |
| `order_products__train.csv` | Contains details about products in the training set of customer orders. |
| `order_products__prior.csv` | Includes information about products included in prior customer orders |
| `products.csv` | Contains details about products, including aisle and department IDs. |


Refer to the [Data Dictionary.docx](https://github.com/user-attachments/files/20435363/Data.Dictionary.docx)
 for a detailed description of each dataset and its columns..

---

## 🎯 Project Objectives

- Understand which products are most reordered and when.
- Identify user behavior trends (e.g., peak order times, reorder frequency).
- Investigate aisle and department-wise order distributions.
- Optimize business decisions using data-driven insights.

---

## 🧹 Data Cleaning

All relevant CSVs were **imported into a MySQL database using the Table Data Import Wizard** (via MySQL Workbench). This allowed for efficient loading of large datasets without manual row insertion.

> ⚠️ The tables were **not created or populated manually** using `INSERT` statements. Instead, the import wizard handled table creation and data insertion automatically during the CSV import process.

Once imported, Column data types were reviewed and adjusted as needed (e.g., converting text to integers where appropriate).. Null values and duplicates were also checked and cleaned as needed

Constraints: Necessary constraints (e.g., primary keys, foreign keys, NOT NULL) were added to enforce data integrity.

New Fields: A new column simulated_order_date was added to the orders table to support further analysis.

New Tables: A backup table was created to preserve original data before transformation or deletion.

Data Quality Checks: Null values: Identified and handled appropriately (e.g., removal or imputation), Duplicates: Detected and removed to ensure unique records.

Example:
```sql
-- Check for duplicate in the aisles table
select aisle_id, aisle, count(*) as count from aisles group by aisle_id, aisle having count > 1;

-- Check for null values in the orders table
select * from orders where order_id is null or user_id is null or eval_set is null or order_number is null
or order_dow is null or order_hour_of_day is null or days_since_prior_order is null;

-- check for bad products and orders in the order_products_prior table
select * from order_products_prior where product_id not in (select product_id from products)  
or order_id not in (select order_id from orders);

-- Backup bad rows from order_products_prior
create table bad_order_products_prior as select * from order_products_prior
where product_id not in (select product_id from products) or order_id not in (select order_id from orders);

-- Delete invalid product_ids from order_products_prior
set sql_safe_updates = 0;
delete from order_products_prior
where product_id not in (select product_id from products) or order_id not in (select order_id from orders);

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

-- Add Foreign Key to order_products_train
alter table order_products_train
add constraint fk_opt_order foreign key (order_id) references orders(order_id),
add constraint fk_opt_product foreign key (product_id) references products(product_id);
```

---

## 🔍 Data Exploration and Insights

### 1️⃣ What are the top 10 most frequently reordered products?

```sql
select p.product_name, count(*) as reorder_count from order_products_prior opp
join products p on opp.product_id = p.product_id where opp.reordered = 1 
group by p.product_name order by reorder_count desc limit 10;
```

### 2️⃣ Can we find products that are often bought together on weekends vs. weekdays?

```sql
select opp1.product_id as product_1, opp1.product_id as product_2, o.order_dow, count(*) as frequency
from order_products_prior as opp1 join order_products_prior as opp2
join orders as o on opp1.order_id = o.order_id
where o.order_dow in (0, 6)
group by opp1.product_id, opp2.product_id, o.order_dow order by frequency desc limit 10;
```

### 3️⃣ What are the different customer segments based on purchase recency, frequency and monetary?

```sql
select r.user_id, r.recency_days, f.total_orders, m.total_products,
 -- Recency Segment
case
        when r.recency_days <= 7 then 'Active'
        when r.recency_days <= 30 then 'Recent'
		when r.recency_days <= 90 then 'Dormant'
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
```

### 4️⃣ What percentage of customers have churned in the past quarter?

```sql
select round(100.0 * count(*) / (select count(distinct user_id) from orders), 2) as churned_percentage
from (select user_id, max(simulated_order_date) as last_order from orders group by user_id) as last_orders
where last_order < curdate() - interval 90 day;

```

### 5️⃣ What are the top 5 product combinations that are most frequently purchased together?

```sql
select opp1.product_id as product_1, opp2.product_id as product_2,
case
when o.order_dow in (0,6) then 'Weekend' else 'Weekday' end as day_type, count(*) frequency
from order_products_prior as opp1 join order_products_prior as opp2 on opp1.order_id = opp2.order_id
and opp1.product_id < opp2.product_id
join orders as o on opp1.order_id = o.order_id
group by product_1, product_2, day_type order by frequency desc limit 10;
```

---

## ✅ Recommendation

Based on insights:

1. **Promote High Reorder Products**  
   Items like bananas, bag of organic bananas, and organic strawberries consistently appear in reorders—great candidates for loyalty or subscription services.

2. **Optimize Staffing Around Peak days**  
   Orders peak during week. Warehousing and delivery teams can be optimized around this window.

3. **Personalized Marketing by Department**  
   Users frequently order from departments like produce. Marketing campaigns can leverage this for personalization.

4. **Bundle Suggestions from High-Reorder Aisles**  
   Aisles like ‘banana’ and ‘organic strawberry’ have strong reorder trends—bundle recommendations here can boost cart size.

---

## 🧾 Conclusion

This analysis demonstrates the value of SQL in extracting insights from large transactional datasets. We’ve uncovered trends around user behavior, reorder likelihood, and high-performing departments—all of which can inform marketing, stocking, and user engagement strategies for Instacart or any similar retail business.

---

## 🛠 Tech Stack

- SQL (MySQL)
- MySQL Workbench
- Git & GitHub

---

> 💬 *Feel free to explore the queries, suggest improvements, or fork the project to build your own insights!*
