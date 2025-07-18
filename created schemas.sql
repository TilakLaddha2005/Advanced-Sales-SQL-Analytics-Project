-- create schemas

create table customers(
customer_id int primary key,
first_name varchar(100),
last_name varchar(100),
gender varchar(50),
dob date,
city varchar(100),
state_ varchar(100),
signup_date date,
segment varchar(50),
annual_income float
);

create table products(
product_id int primary key,
product_name varchar(200),
category varchar(100),
sub_category varchar(100),
brand varchar(50),
cost_price float,
selling_price float,
launch_date date
);

create table orders(
order_id int primary key,
customer_id int,
order_date date,
product_id int,
quantity int,
unit_price float,
discount_pct float,
revenue float,
cost_ float,	
profit float,
constraint orders_customers_fk foreign key (customer_id) references customers(customer_id),
constraint orders_products_fk foreign key (product_id) references products(product_id)
);

create table payments(
payment_id int primary key,
order_id int,
payment_date date,
payment_method varchar(100),
transaction_amount float,
card_type varchar(50),
finance_charges float,
installment_plan varchar(10),
interest_rate float,
constraint payments_orders_fk foreign key (order_id) references orders(order_id)
)

