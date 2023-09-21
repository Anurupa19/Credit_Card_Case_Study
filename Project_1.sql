select * from credit_card;

select count(*) from credit_card;
-- There are total 26,052 records in the card credit data.

select distinct card_type from credit_card;
-- There are 4 types of credit card which are considered here, these are Silver, Gold, Platinum and Signature.

select distinct exp_type from credit_card;
-- 6 types of expenses are considered here which are Entertainment, Food, Bills, Fuel, Travel and Grocery.

select distinct city from credit_card;
-- There are 986 cities from different parts of the country which are considered for analysis.

-- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends
with cte1 as
(select city, sum(amount) as spend_amount
from credit_card
group by city),
cte2 as (select sum(amount) as total_spend from credit_card)
select top 5 city, spend_amount, round(spend_amount*1.0/total_spend*100,2) as percentage_contribution
from cte1 inner join cte2 on 1=1
order by spend_amount desc;

-- write a query to print highest spend month and amount spent in that month for each card type
with cte1 as 
(select card_type, DATEPART(month, transaction_date) as month_of_spend, sum(amount) as total_spend
from credit_card
group by card_type, DATEPART(month, transaction_date)),
spend_month as (select cte1.*, rank() over(partition by card_type order by total_spend desc) as rn
from cte1)
select * from spend_month
where rn=1;

with cte1 as 
(select card_type, datepart(year, transaction_date) as year_of_spend, DATEPART(month, transaction_date) as month_of_spend, sum(amount) as total_spend
from credit_card
group by card_type, DATEPART(month, transaction_date), datepart(year, transaction_date)),
spend_month as (select cte1.*, rank() over(partition by card_type order by total_spend desc) as rn
from cte1)
select * from spend_month
where rn=1;

-- write a query to find city which had lowest percentage spend for gold card type
with cte1 as
(select city, card_type, sum(amount) as spend_amount, 
sum(case when card_type = 'Gold' then amount end) as gold_amount
from credit_card
group by city, card_type)
select top 1 city, sum(gold_amount)*1.0/sum(spend_amount) as gold_ratio
from cte1
group by city
having sum(gold_amount)*1.0/sum(spend_amount) is not null
order by gold_ratio;

-- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte1 as 
(select city, exp_type, sum(amount) as total_amount
from credit_card
group by city, exp_type),
cte2 as 
(select *, 
rank() over(partition by city order by total_amount asc) as rank_asc,
rank() over(partition by city order by total_amount desc) as rank_desc
from cte1)
select city,  
max(case when rank_desc=1 then exp_type end) as highest_expense_type,
min(case when rank_asc=1 then exp_type end) as lowest_expense_type
from cte2
group by city;

-- write a query to find percentage contribution of spends by females for each expense type
with cte1 as
(select exp_type, 
sum(case when gender='F' then amount else 0 end) as total_amount
from credit_card
group by exp_type),
cte2 as (select exp_type, sum(amount) as total from credit_card group by exp_type)
select cte1.exp_type, round(total_amount*1.0/total*100,2) as percentage_female_contribution
from cte1 inner join cte2 on cte1.exp_type=cte2.exp_type
order by percentage_female_contribution desc;

select exp_type,
sum(case when gender='F' then amount else 0 end)*1.0/sum(amount)*100 as percentage_female_contribution
from credit_card
group by exp_type
order by percentage_female_contribution desc;

-- write a query to print the transaction details(all columns from the table) for each card type when
-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte1 as
(select *, sum(amount) over(partition by card_type order by transaction_date, transaction_id) as total_spend
from credit_card),
cte2 as
(select *, rank() over(partition by card_type order by total_spend) as rn
from cte1
where total_spend>= 1000000)
select * from cte2
where rn=1;

-- which card and expense type combination saw highest month over month growth in Jan-2014
with cte1 as
(select card_type, exp_type, 
DATEPART(year, transaction_date) as year_of_transaction,
DATEPART(month, transaction_date) as month_of_transaction,
sum(amount) as total_spend
from credit_card
group by card_type, exp_type, DATEPART(year, transaction_date), DATEPART(month, transaction_date)),
cte2 as
(select *, lag(total_spend) over(partition by card_type, exp_type order by year_of_transaction, month_of_transaction) as prev_month_spend
from cte1)
select top 1 *, (total_spend-prev_month_spend)*1.0/prev_month_spend*100 as mom_growth
from cte2
where prev_month_spend is not null and year_of_transaction=2014 and month_of_transaction=1
order by (total_spend-prev_month_spend)*1.0/prev_month_spend*100 desc;

-- during weekends which city has highest total spend to total no of transcations ratio
select top 1city, sum(amount)*1.0/count(1) as transaction_ratio
from credit_card
where DATEPART(weekday,transaction_date) in (1,7)
group by city
order by transaction_ratio desc;

with cte1 as 
(select city, sum(amount) as total_spend
from credit_card
where DATEPART(weekday, transaction_date) in (1,7)
group by city),
cte2 as
(select city, count(1) as total_count
from credit_card
where DATEPART(weekday,transaction_date) in (1,7)
group by city)
select top 1 cte1.city, total_spend*1.0/total_count as transaction_ratio
from cte1 join cte2
on cte1.city=cte2.city
order by transaction_ratio desc;

-- which city took least number of days to reach its 500th transaction after the first transaction in that city
with cte as (select *, row_number() over(partition by city order by transaction_date) as rn
from credit_card)
select top 1 city, min(transaction_date) as min_date, max(transaction_date) as max_date, 
DATEDIFF(day, min(transaction_date), max(transaction_date)) as diff_in_days 
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by diff_in_days asc;
