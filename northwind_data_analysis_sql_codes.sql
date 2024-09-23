--NORTHWIND COMPANY SALES - PRODUCT - CUSTOMER - LOGISTICS ANALYSIS SQL QUERIES--


--1) How many products are there in which category according to price range and what is their total stock and stock value?

WITH price_ranges AS (
    SELECT 
        p.product_id,
        p.unit_price,
        p.unit_in_stock,
        c.category_name,
        CASE 
            WHEN p.unit_price < 10 THEN '0-10'
            WHEN p.unit_price BETWEEN 10 AND 20 THEN '10-20'
            WHEN p.unit_price BETWEEN 20 AND 50 THEN '20-50'
            ELSE '50+' 
        END AS price_range
    FROM products p
    JOIN categories c ON p.category_id = c.category_id
)
SELECT 
    price_range,
    category_name,
    COUNT(product_id) AS product_count,
    SUM(unit_in_stock) AS total_stock,
    SUM(unit_price * unit_in_stock) AS total_stock_value
FROM price_ranges
GROUP BY price_range, category_name
ORDER BY price_range;


--2) Which product categories generate the most sales revenue and what is their total sales revenue?

SELECT 
    c.category_name,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales_revenue
FROM order_details od
JOIN products p ON od.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_sales_revenue DESC;


--3) How many products were sold with and without discounts and what was their sales revenue?

SELECT 
    CASE 
        WHEN od.discount > 0 THEN 'Discounted'
        ELSE 'Non-Discounted'
    END AS discount_status,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales_revenue
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
GROUP BY discount_status;
4) İndirimli ve indirimsiz satılan ürün sayısı ve bunların satış gelirinin kategori bazlı analizi ?

SELECT 
    c.category_name,
    CASE 
        WHEN od.discount > 0 THEN 'Discounted'
        ELSE 'Non-Discounted'
    END AS discount_status,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales_revenue
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
JOIN products p ON od.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name, discount_status
ORDER BY c.category_name, discount_status;


--5) Number of products sold with and without discounts and analysis of their sales revenue by category and month?

SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    c.category_name,
    CASE 
        WHEN od.discount > 0 THEN 'Discounted'
        ELSE 'Non-Discounted'
    END AS discount_status,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales_revenue
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
JOIN products p ON od.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY month, c.category_name, discount_status
ORDER BY month, c.category_name, discount_status;


--6) Number of discounted and non-discounted products sold and analysis of their sales revenue by category and year?

SELECT 
    DATE_TRUNC('year', o.order_date) AS year,
    c.category_name,
    CASE 
        WHEN od.discount > 0 THEN 'Discounted'
        ELSE 'Non-Discounted'
    END AS discount_status,
    COUNT(DISTINCT o.order_id) AS number_of_orders,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales_revenue
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
JOIN products p ON od.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY year, c.category_name, discount_status
ORDER BY year, c.category_name, discount_status;

--7) Who are the customers who ordered the most and how much did they order?

SELECT 
    c.customer_id,
    c.company_name,
    COUNT(o.order_id) AS total_orders,
    SUM(od.unit_price * od.quantity) AS total_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY total_orders DESC, total_order_value DESC
LIMIT 10;


--8) Who made the most sales among the employees and how much did they sell?

SELECT 
    e.employee_id,
    e.first_name,
    e.last_name,
    COUNT(o.order_id) AS total_orders,
    SUM(od.unit_price * od.quantity) AS total_sales
FROM employees e
JOIN orders o ON e.employee_id = o.employee_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_orders DESC, total_sales DESC
LIMIT 10;


--9) Which cities are the most ordered by product category?

WITH category_city_orders AS (
    SELECT 
        c.category_name,
        o.ship_city,
        COUNT(od.order_id) AS total_orders,
        SUM(od.quantity) AS total_quantity
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    JOIN categories c ON p.category_id = c.category_id
    JOIN orders o ON od.order_id = o.order_id
    GROUP BY c.category_name, o.ship_city
),
ranked_orders AS (
    SELECT 
        category_name,
        ship_city,
        total_orders,
        total_quantity,
        ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY total_orders DESC) AS rank
    FROM category_city_orders
)
SELECT 
    category_name,
    ship_city,
    total_orders,
    total_quantity
FROM ranked_orders
WHERE rank = 1
ORDER BY total_orders DESC;


--10) What is the average delivery time for orders?

SELECT 
    AVG(shipped_date - order_date) AS avg_delivery_time
FROM orders
WHERE shipped_date IS NOT NULL;


--11) What is the average delivery time of orders by shipping company?

SELECT 
    s.company_name,
    AVG(o.shipped_date - o.order_date) AS avg_delivery_time
FROM orders o
JOIN shippers s ON o.ship_via = s.shipper_id
WHERE o.shipped_date IS NOT NULL
GROUP BY s.company_name;


--12) Monthly analysis of the number of orders delivered on time, number of delayed orders and number of undelivered orders?

SELECT 
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    COUNT(CASE WHEN shipped_date <= required_date THEN 1 END) AS on_time_deliveries,
    COUNT(CASE WHEN shipped_date > required_date THEN 1 END) AS late_deliveries,
    COUNT(CASE WHEN shipped_date IS NULL THEN 1 END) AS undelivered_orders
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month;


--13) What is the average delivery time of shipping companies per month?

SELECT 
    TO_CHAR(o.order_date, 'YYYY-MM') AS month,
    s.company_name AS shipper,
    ROUND(AVG(o.shipped_date - o.order_date), 2) AS avg_delivery_time
FROM orders o
JOIN shippers s ON o.ship_via = s.shipper_id
WHERE o.shipped_date IS NOT NULL
GROUP BY TO_CHAR(o.order_date, 'YYYY-MM'), s.company_name
ORDER BY month, shipper;


--14) What is the number of orders per transportation company?

SELECT 
    s.company_name AS shipper,
    COUNT(o.order_id) AS order_count
FROM orders o
JOIN shippers s ON o.ship_via = s.shipper_id
GROUP BY s.company_name
ORDER BY order_count DESC;

--15) What is the success ranking of transportation companies?

SELECT 
    s.company_name AS shipper,
    AVG(o.shipped_date - o.order_date) AS avg_delivery_time,
    COUNT(CASE WHEN o.shipped_date > o.required_date THEN 1 END) AS late_deliveries
FROM orders o
JOIN shippers s ON o.ship_via = s.shipper_id
WHERE o.shipped_date IS NOT NULL
GROUP BY s.company_name
ORDER BY avg_delivery_time, late_deliveries;


--16) Analysis of the top 5 customers with the most delays ?

SELECT 
    c.customer_id,
    c.company_name,
    COUNT(o.order_id) AS late_delivery_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.shipped_date > o.required_date
GROUP BY c.customer_id,c.company_name
ORDER BY late_delivery_count DESC
LIMIT 5;

--17) RFM Analysis :

WITH recency_table AS (
    SELECT 
        o.customer_id, 
        MAX(o.order_date) AS last_order_date
    FROM orders o
    GROUP BY o.customer_id
),
frequency_table AS (
    SELECT 
        o.customer_id, 
        COUNT(o.order_id) AS order_count
    FROM orders o
    GROUP BY o.customer_id
),
monetary_table AS (
    SELECT 
        o.customer_id, 
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spent
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.customer_id
),
recency_segment AS (
    SELECT 
        customer_id, 
        NTILE(4) OVER (ORDER BY CURRENT_DATE - last_order_date) AS recency_segment
    FROM recency_table
),
frequency_segment AS (
    SELECT 
        customer_id, 
        NTILE(4) OVER (ORDER BY order_count DESC) AS frequency_segment
    FROM frequency_table
),
monetary_segment AS (
    SELECT 
        customer_id, 
        NTILE(4) OVER (ORDER BY total_spent DESC) AS monetary_segment
    FROM monetary_table
)
SELECT 
    r.customer_id, 
    r.recency_segment, 
    f.frequency_segment, 
    m.monetary_segment
FROM recency_segment r
JOIN frequency_segment f ON r.customer_id = f.customer_id
JOIN monetary_segment m ON r.customer_id = m.customer_id;
