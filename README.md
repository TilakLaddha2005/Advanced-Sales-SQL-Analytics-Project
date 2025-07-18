# Advanced-Sales-SQL-Analytics-Project

Project Overview

This project focuses on advanced business analytics using SQL, applied to a transactional dataset containing customer, order, product, and payment-level data. The objective is to derive actionable insights such as customer segmentation, churn prediction, seasonality, and financial performance.

Objectives

- Perform customer segmentation using RFM analysis
- Understand customer lifecycle and behavior through cohort analysis
- Identify high-value customers and churn risks
- Analyze pricing impact and discount elasticity
- Track profit, revenue, and contribution metrics
- Detect seasonality trends and high-value transactions

Dataset Information

The project uses structured tables that include the following
- customers – Customer details
- orders – Transaction-level data including revenue, cost, profit, and discounts
- products – Product category and price details
- payments – Payment method, EMI flags, and transaction dates

SQL Queries and Business Questions

1  RFM segmentation – score customers based on Recency, Frequency, and Monetary values  
2  Cohort analysis – track user engagement over cohort months  
3  Year-over-Year growth – analyze growth in revenue, customers, and orders  
4  Next-best product – identify products frequently bought together using lift  
5  Price elasticity – estimate sensitivity of revenue to discounts across categories  
6  Contribution margin – calculate profit percentages by category and payment method  
7  Seasonality index – monthly revenue to highlight above-trend periods  
8  Churn prediction – classify customers as active, churning, or churned  
9  High-value order alerts – flag orders above 90th percentile revenue with high discount  
10 EMI utilization – measure the share of total revenue paid via EMI over time  

Key Insights

- Customers with high recency, frequency, and monetary values are identified as Gold segment  
- Cohort analysis reveals strong repeat order behavior within the first few months  
- Pricing elasticity varies by product category, with some being more discount sensitive  
- EMI usage contributes significantly to total revenue in select months  
- High-value orders are rare but contribute a large share of profit  

Tools Used

- SQL (PostgreSQL or compatible)

