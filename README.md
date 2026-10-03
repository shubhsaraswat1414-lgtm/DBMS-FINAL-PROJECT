Newspaper Vendor Delivery & Subscription Management System

A DBMS Case Study 123 project for managing newspaper households, publications, daily deliveries, and monthly billing using SQL and NoSQL (MongoDB).

📌 Project Overview

This project models a newspaper vendor system where households can receive multiple newspaper publications. The database records daily deliveries and maintains monthly billing information.

The project demonstrates both relational database concepts using SQL and document-based data modeling using MongoDB.

🗂️ Database Structure

The SQL database consists of four main tables:

* HOUSEHOLDS — stores household/customer information such as ID, name, city and monthly bill.
* PUBLICATIONS — stores newspaper information such as publication name, price per copy and frequency.
* DAILY_DELIVERIES — records which publication was delivered to which household, number of papers and delivery date.
* MONTHLY_BILLS — stores monthly billing information including billing month, papers delivered and amount.💾 SQL Implementation

The project contains 10 SQL queries demonstrating:

1. Filtering deliveries using WHERE and BETWEEN
2. Three-table JOIN
3. GROUP BY and HAVING
4. Nested subquery with IN
5. Correlated subquery with MAX
6. Average billing with a subquery
7. Aggregate revenue analysis
8. City-wise billing summary
9. Multiple filtering conditions using AND
10. NOT EXISTS with a correlated subquery👨‍💻 Project

Case Study: 123
Project: Newspaper Vendor Delivery and Subscription
Student: Shubh Saraswat
Program: B.Tech CSE
Specialization: AI/ML
Semester: III
Academic Year: 2025–29
