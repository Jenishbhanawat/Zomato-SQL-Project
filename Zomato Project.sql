create database zomato;
use zomato;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer, gold_signup_date date); 

INSERT INTO goldusers_signup(userid, gold_signup_date) 
 VALUES (1, '2017-09-22'),
(3, '2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer, signup_date date); 

INSERT INTO users(userid, signup_date) 
 VALUES (1, '2014-09-02'),
(2, '2015-01-15'),
(3, '2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer, created_date date, product_id integer); 

INSERT INTO sales(userid, created_date, product_id) 
 VALUES (1, '2017-04-19', 2),
(3, '2019-12-18', 1),
(2, '2020-07-20', 3),
(1, '2019-10-23', 2),
(1, '2018-03-19', 3),
(3, '2016-12-20', 2),
(1, '2016-11-09', 1),
(1, '2016-05-20', 3),
(2, '2017-09-24', 1),
(1, '2017-03-11', 2),
(1, '2016-03-11', 1),
(3, '2016-11-10', 1),
(3, '2017-12-07', 2),
(3, '2016-12-15', 2),
(2, '2017-11-08', 2),
(2, '2018-09-10', 3);

drop table if exists product;
CREATE TABLE product(product_id integer, product_name text, price integer); 

INSERT INTO product(product_id, product_name, price) 
 VALUES
(1, 'p1', 980),
(2, 'p2', 870),
(3, 'p3', 330);

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;

-- Q1 What is the total amount each customer has spent on zomato?
select userid, sum(price) as total_money_spent from sales left join product using(product_id) group by userid;

-- Q2 How many days each customer has visited zomato?
with cte as (select sales.userid, count(sales.created_date) as e1, count(goldusers_signup.gold_signup_date) as e2, count(users.signup_date) as e3 from users left join sales using(userid) left join goldusers_signup using(userid) group by sales.userid) select userid, e1+e2+e3 as total_days_spent from cte;
 
-- Q3 What was the first product purchased by each customer?
with cte as (select *, row_number() over (partition by userid order by created_date asc range between unbounded preceding and unbounded following) as rnk from sales) select userid, product_id from cte where rnk = 1;

-- Q4 Whats is the most purchased item on the menu and how many times was it purchased by all customers?
select userid, count(*) as total_buys from sales where product_id = (select product_id from (select product_id,count(*) as total from sales group by product_id order by total desc limit 1) as abc) group by userid order by userid asc;

-- Q5 Which Item was the most popular for each customer?
with cte as (select userid, product_id, count(*) as total, dense_rank()over (partition by userid order by count(*) desc) as rnk from sales group by userid, product_id order by userid, product_id) select userid,product_id from cte where rnk = 1;

-- Q6 Which item was purchased first by the customer when they becoame a gold member?
select userid, product_id from (select *, row_number() over (partition by userid order by created_date) as rnk from sales join goldusers_signup using(userid) where gold_signup_date < created_date) as abc where rnk = 1;
 
-- Q7 Which item was purchased by the customer just before they becoame a gold member? 
select userid, product_id from (select *, row_number() over (partition by userid order by created_date desc) as rnk from sales join goldusers_signup using(userid) where created_date < gold_signup_date) as abc where rnk = 1;

-- Q8 What is total orders and amount spent for each member before they become a member?
select userid, count(*) as total_orders, sum(price) as amount_spent from sales left join goldusers_signup using(userid) left join product using(product_id) where created_date < gold_signup_date group by userid;

-- Q9 If buying each product generates points and each product has different purchasing points for eg p1 5Rs = 1 point, for p2 10Rs = 5 points and p3 5Rs = 1 point. Calculate a). total points earned by each customer b). for which product has given more points.
-- a). 
select userid, sum(points) as total_points from (select userid, product_name, round(sum(price),0) as amount, round(sum(price)/5 ,0) as multiples, case when product_name = "p1" then round(sum(price)/5 ,0)*1 when product_name = "p2" then round(sum(price)/5 ,0)*2.5 else round(sum(price)/5 ,0)*1 end as points  from sales join product using(product_id) group by userid, product_name) as abc group by userid order by userid;
-- b). 
select product_name, sum(points) as total_points from (select userid, product_name, round(sum(price),0) as amount, round(sum(price)/5 ,0) as multiples, case when product_name = "p1" then round(sum(price)/5 ,0)*1 when product_name = "p2" then round(sum(price)/5 ,0)*2.5 else round(sum(price)/5 ,0)*1 end as points  from sales join product using(product_id) group by userid, product_name) as abc group by product_name;

-- Q10 In the first one year after customer joins gold membership (including the joining date) irrespective of what the customer has purchased they earn 5 points for every 10 Rs spent. Which customers have earned more points in that thier first years?
select userid, round(points,0) as points from (select userid, sum(price) as amount, sum(price)/10 as multiples, sum(price)*5/10 as points from sales join goldusers_signup using(userid) join product using(product_id) where created_date > gold_signup_date and timestampdiff(day,gold_signup_date,created_date) < 365 group by userid) as abc;

-- Q11 Rank all the transactions of every customer
select *,rank() over (partition by userid order by created_date) as rnk from sales;

-- Q12 Rank all the transactions for each gold member and for a non-gold member return NA in the rank.
select *, case when created_date > gold_signup_date then row_number() over (partition by userid order by created_date desc) else "NA" END as "rank" from sales left join goldusers_signup using(userid);

