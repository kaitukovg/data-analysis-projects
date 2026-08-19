# 🍕 Pizza Sales Analysis

An exploratory data analysis project focused on understanding sales performance, product demand, customer ordering behavior, and revenue dynamics of a pizza restaurant.

The project combines PostgreSQL, SQL, Python, Pandas, Matplotlib and Seaborn to transform raw transactional data into actionable business insights.

---

## 🎯 Project Objective

The main goal of the project is to identify the key factors driving the restaurant's revenue and understand how sales vary across products, order sizes, time periods and other dimensions.

The analysis focuses on questions such as:

- Which pizzas generate the most revenue?
- How concentrated is revenue across the product range?
- How does revenue change throughout the year?
- When are the busiest hours?
- How does the number of pizzas in an order affect the average check?
- Which pizza categories and sizes contribute the most revenue?
- Are there products with particularly low demand?

---

## 🗂️ Dataset

The dataset contains transactional pizza sales data.

The main entities are:

- `orders` — order date and time
- `order_details` — pizzas and quantities included in each order
- `pizzas` — pizza size and price
- `pizza_types` — pizza names and categories

The analysis covers one year of sales data.

---

## 🛠️ Tools & Technologies

- **PostgreSQL** — data storage, transformation and aggregation
- **SQL** — joins, aggregations and analytical views
- **Python** — data analysis
- **Pandas** — data manipulation
- **Matplotlib** — visualization
- **Seaborn** — statistical visualization
- **Jupyter Notebook** — analysis and presentation

---

## 🔄 Data Preparation

Several SQL views were created to simplify the analytical workflow.

### `pizza_table`

Detailed transactional view where:

> **1 row = 1 pizza item within an order**

It contains information about:

- order
- month
- hour
- pizza
- category
- size
- quantity
- price
- revenue

### `order_summary`

Aggregated order-level view where:

> **1 row = 1 order**

It is used to analyze:

- total pizzas per order
- order revenue
- average check
- order behavior
- hourly and monthly dynamics

This separation allows the analysis to work with both detailed product-level data and aggregated order-level data.

---

## 📊 Analysis

The project covers several analytical areas.

### Product Performance

Analysis of pizza sales and revenue identifies the products that contribute most to the restaurant's financial performance.

Revenue share is calculated to understand how strongly the business depends on its best-performing products.

### Revenue Concentration

The top 10 pizza products account for approximately **44.5% of total revenue**.

This indicates that a relatively limited number of products make a substantial contribution to the restaurant's overall revenue.

### Monthly Sales Dynamics

Monthly revenue and order volume are analyzed to understand changes in business activity throughout the year.

The highest monthly revenue was recorded in **July — $72,557.90**, while the lowest was recorded in **October — $64,027.60**.

The difference between the maximum and minimum monthly revenue is approximately **13.3%**.

July also recorded the highest number of orders, with **1,935 orders**.

### Pizza Categories

Revenue and sales volume are compared across the main pizza categories:

- Classic
- Supreme
- Chicken
- Veggie

### Pizza Sizes

Different pizza sizes are analyzed by quantity sold and revenue contribution.

The **Large (L)** size is the strongest contributor to revenue, accounting for approximately **45.9% of total revenue**.

The **XXL** size has very low demand compared with other sizes, with only **28 units sold** and approximately **$1,006.60 in revenue**.

### Order Behavior

Order-level analysis examines:

- number of pizzas per order
- average check
- relationship between order size and revenue
- changes in ordering behavior over time

### Hourly Sales

Sales activity is analyzed by hour to identify periods with higher revenue and order volumes.

This can help identify periods of increased operational workload and potential opportunities for staffing and promotions.

---

## 💡 Key Business Insights

The analysis suggests several important patterns:

1. Revenue is significantly concentrated among the best-performing products. The top 10 pizzas generate around 44.5% of total revenue.

2. Monthly revenue varies throughout the year, with July showing the highest revenue and order volume.

3. Large pizzas are a major contributor to overall revenue, representing approximately 45.9% of total revenue.

4. XXL pizzas have substantially lower demand than other sizes and may require additional evaluation from an assortment-management perspective.

5. Order-level analysis shows that larger orders generally generate higher checks.

---

## 📌 Business Recommendations

Based on the analysis, several areas can be considered for further business action:

- Maintain high availability of the products responsible for the largest share of revenue.
- Use best-performing pizzas as key products for promotions and upselling.
- Investigate the economic efficiency of low-demand sizes such as XXL.
- Consider sales patterns by hour when planning operational resources.
- Monitor periods with lower order volumes for potential promotional campaigns.
- Continue tracking revenue concentration to identify changes in customer preferences.
