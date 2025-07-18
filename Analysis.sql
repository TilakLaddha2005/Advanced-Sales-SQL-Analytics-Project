-----------------------------------------------------------------------

-- 1. RFM segmentation – score customers on Recency, Frequency, Monetary .

create view rfm_segmentation as
with customer_data as(
	select
	c.customer_id,
	max(o.order_date) as last_order_date,
	((select max(order_date) from orders) - max(o.order_date) ) as recency,
	count(o.order_id) as frequency,
	cast(sum(o.revenue) as decimal(10,2)) as monetary
	from customers c
	join orders o on o.customer_id = c.customer_id
	group by c.customer_id),
	
rfm_score as(
	select 
	cd.*,
	case when recency <= 30 then 5 
	     when recency <= 60 then 4
		 when recency <= 90 then 3
		 when recency <= 110 then 2
		 else 1 end as r_score,
	case when frequency >= 15 then 5 
	     when frequency >= 10 then 4
		 when frequency >= 7 then 3
		 when frequency >= 4 then 2
		 else 1 end as f_score,
	case when monetary >= 75000 then 5 
	     when monetary >= 50000 then 4
		 when monetary >= 25000 then 3
		 when monetary >= 15000 then 2
		 else 1 end as m_score
	from customer_data cd)

select *,
case when r_score >= 4 and f_score >= 4 and m_score >= 4 then 'gold'
     when r_score > 2 and f_score > 2 and m_score > 2 then 'silver'
	 when r_score > 1 and f_score > 1 and m_score > 1 then 'bronze'
	 else 'common' end as customer_segment,
case when r_score >= 3 then 'save'
     when r_score >= 1 then 'churning'
	 else 'churned' end as recency_segment,
case when f_score >= 3 then 'regular'
     when f_score >= 1 then 'one time'
	 else 'churned' end as frequency_segment,
case when m_score >= 4 then 'high value'
     when m_score >= 2 then 'medium value'
	 else 'low value' end as monetary_segment
from rfm_score;

-----------------------------------------------------------------------

-- 2. Cohort year - month analysis

with cohort_months as(
	select 
	c.customer_id,
	extract(months from o.order_date) as month_number,
	to_char(o.order_date , 'Month') as cohort_month
	from customers c 
	join orders o on o.customer_id = c.customer_id)

select 
date_part( 'year' , o.order_date ) as years,
rank() over(partition by date_part( 'year' , o.order_date ) order by cm.month_number) as month_number,
cm.cohort_month,
count(distinct cm.customer_id) as total_signup,
count(o.order_date) as total_orders,
cast(sum(p.transaction_amount) as decimal(10,2)) as revenue
from cohort_months cm
join orders o on cm.customer_id = o.customer_id
join payments p on p.order_id = o.order_id
group by years , month_number , cm.cohort_month ;

-----------------------------------------------------------------------

-- 3. year - over - year (yoy growth) for revenue , total customers , total orders

select 
date_part( 'year' , o.order_date) as years,

sum(o.revenue) as total_revenue,
lag(sum(o.revenue)) over(order by date_part('year' , o.order_date)) as prev_year_revenue,
((sum(o.revenue) - lag(sum(o.revenue)) over(order by date_part('year' , o.order_date))) * 100 
/ lag(sum(o.revenue)) over(order by date_part('year' , o.order_date))) as yoy_growth_revenue,

count(distinct c.customer_id) as total_customers,
lag(count(distinct c.customer_id)) over(order by date_part( 'year' , o.order_date)) as prv_year_customers,
((count(distinct c.customer_id) - lag(count(distinct c.customer_id)) over(order by date_part( 'year' , o.order_date))) * 100 
/ lag(count(distinct c.customer_id)) over(order by date_part( 'year' , o.order_date))) as yoy_growth_customers,

count(o.order_id) as total_orders,
lag(count(o.order_id)) over(order by date_part( 'year' , o.order_date)) as prev_year_orders,
((count(o.order_id) - lag(count(o.order_id)) over(order by date_part( 'year' , o.order_date))) * 100 
/ lag(count(o.order_id)) over(order by date_part( 'year' , o.order_date))) as yoy_growth_orders

from orders o
join customers c on c.customer_id = o.customer_id
group by years;

-----------------------------------------------------------------------

-- 4. Next-best product – market-basket lift to recommend an item likely to be bought with 

select 
pro1.category as category_of_1,
pro1.product_name as name_of_1,
o1.product_id as p1,
o2.product_id as p2,
pro2.product_name as name_of_2,
pro2.category as category_of_2,
count(*) as total_count
from orders o1
join orders o2 on o2.order_id = o1.order_id and o2.product_id <> o1.product_id
join products pro1 on pro1.product_id = o1.product_id
join products pro2 on pro2.product_id = o2.product_id
group by pro1.category , pro1.product_name , o1.product_id , o2.product_id , pro2.product_name, pro2.category;

-----------------------------------------------------------------------

-- 5. Price-elasticity analysis – estimate elasticity per category using paired discounts vs revenue change.

select 
p.category,
cast(avg(o.discount_pct) as decimal(10,2)) as avg_discount,
sum(o.discount_pct * o.revenue) as total_discount_value,
sum(o.revenue) as total_revenue,
(sum(o.revenue) - sum(o.discount_pct * o.revenue)) as lost_amount,
cast(corr(o.discount_pct , o.revenue) as decimal(10,2)) as price_elasticity
from products p
join orders o on o.product_id = p.product_id
group by p.category

-- ***** A negative correlation means increasing discount tends to increase revenue (elastic). ***** --

-----------------------------------------------------------------------

-- 6. Contribution margin – profit % by category and by payment-method finance charges.

select 
p.category,
avg(o.revenue) as avg_revenue,
sum(o.revenue) as total_revenue,
sum(o.cost_) as total_cost,
sum(o.profit) as total_profit,
(sum(o.profit) * 100 / sum(o.revenue)) as profit_pct,
(sum(o.profit) * 100 / (select sum(profit) from orders)) as profit_contribution_pct,
(sum(o.revenue) * 100 / (select sum(revenue) from orders)) as revenue_contribution_pct
from products p
join orders o on o.product_id = p.product_id
group by p.category

-----------------------------------------------------------------------

-- 7. Seasonality index –  monthly revenue to flag above-trend periods.

with yearly_data as(
	select 
	date_part( 'Year' , o.order_date ) as years,
	extract( 'Month' from o.order_date) as month_number,
	to_char(o.order_date , 'Month' ) as months,
	rank() over(partition by date_part( 'Year' , o.order_date ) order by sum(o.revenue)) as rank_per_revenue,
	cast(sum(o.revenue) as decimal(10,2)) as revenue,
	lag(cast(sum(o.revenue) as decimal(10,2))) over(partition by date_part( 'Year' , o.order_date ) order by (extract( 'Month' from o.order_date)) asc) as prev_month_revenue,
	count(distinct o.order_id) as total_orders
	from orders o
	group by years , month_number , months 
	order by years , month_number)

select yd.*,
((yd.revenue - yd.prev_month_revenue) * 100 / yd.prev_month_revenue) as year_mom_growth
from yearly_data yd;

-----------------------------------------------------------------------

-- 8. Churn prediction data-mart and its analysis

with customer_data as(
	select 
	c.customer_id,
	max(o.order_date) as last_order_date,
	(select max(order_date) from orders) - max(o.order_date) as days_since_last_order,
	case when (select max(order_date) from orders) - max(o.order_date) > 500 then 'churned'
	     when (select max(order_date) from orders) - max(o.order_date) > 200 then 'churning'
		 else 'active' end as status
	from customers c
	join orders o on o.customer_id = c.customer_id
	group by c.customer_id)

select 
cd.status,
count(cd.customer_id) as total_customers,
sum(o.revenue) as revenue_from,
sum(o.profit) as profit_from,
(sum(o.revenue) * 100 / (select sum(revenue) from orders) ) as revenue_contribution_pct
from customer_data cd
join orders o on cd.customer_id = o.customer_id
group by cd.status;

-----------------------------------------------------------------------

-- 9. High-value order alerts – identify orders > P90 revenue and > 30 % discount.

with high_rev_value as(
	select 
	percentile_cont(0.9) within group ( order by revenue) as high_revenue
	from orders )

select *
from orders , high_rev_value
where revenue > high_revenue and discount_pct > 0.2 ; 

-----------------------------------------------------------------------

-- 10. EMI utilisation rate – share of revenue paid via EMI, trend YoY.

select 
to_char( p.payment_date , 'Month') as months,
sum(case when p.installment_plan = 'Yes' then p.transaction_amount else 0 end) as amount_from_emi,
sum(p.transaction_amount) as total_amount,
sum(case when p.installment_plan = 'Yes' then p.transaction_amount else 0 end) * 100 / sum(p.transaction_amount) as emi_contribution_pct
from payments p
group by months
order by months;

-----------------------------------------------------------------------