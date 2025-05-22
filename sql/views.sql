

/* Identify  customers with more than one active polices and its total number*/
create view customers_with_more_than_1_policiy_active as 
select  c.customerid as customer_id, count(p.policyid) as policies 
from policies p right join customers c on p.customerid = c.customerid
where current_date between p.start_date  and p.end_date
group by c.customerid
having count(p.policyid) > 1;

/* Calculate the total amount of awards paids for each client for its all policies*/

create view total_awards_paid_for_each_customer as 
with claims_settled as (select claimid , policyID ,settlement_amount from 
claims where claim_status = 'Settled')
select c.first_name as name , c.ssn as ssn , sum(cl.settlement_amount) as total_paid
from  claims_settled cl 
inner join policies p on cl.policyid  = p.policyid 
inner join customers c on c.customerid = p.customerid
group by c.customerid;

/* 
Find all claim where the claim_amount exceeds a certain value, 
and the associated policy cover the value
*/

create view claims_with_big_awards as 
select c.claimid as id_claim ,  p.policyid as id_policy, 
c.claim_amount  as "amount claimed" , p.coverage_amount as "amount covered"
from claims c inner join  policies p on c.policyid = p.policyid
where c.claim_amount > 40000  and p.coverage_amount > c.claim_amount;

/* Find all policies with no payments registered*/
crate view policies_with_any__payment
select policyid
from policies 
where policyid not in (select policyid from payments);


/* counting the number of claim for each type of policy*/

create view count_number_of_claims_by_policy_type
select p.policy_type  as "policy type" , count(claimid) as "number of claims"
from policies p inner join claims c on p.policyid = c.policyid
group by p.policy_type
order by count(claimid) desc;

/* Indentify cutomers without claims ***/


create view customer_without_claims
select c.ssn , c.first_name from customers c
where c.customerid not in (select p.customerid from 
policies p inner join claims cl on p.policyid = cl.policyid);


/* count the number of claims per year grouped by the  type of policy*/

create view count_number_of_claims_by_year_and_policy_type
with claim_year as 
(select policyid , date_part('year' ,claim_date ) as year from claims)
select p.policy_type as "type of policy" , c.year as year, count(c.year)
from policies p inner join claim_year c on p.policyid = c.policyid
group by p.policy_type , c.year
order by count(c.year) desc
;

/* show policies with pending payments in the previous month*/
create view policies_with_pending_payments_previous_month
select policyid from policies
where current_date between start_date and end_date
and policyid not in (
select policyid from payments 
where EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 MONTH') = EXTRACT(MONTH FROM payment_date) and 
EXTRACT(year FROM CURRENT_DATE) = EXTRACT(year FROM payment_date));


/* average number of days between a claim opening and its settlement date*/
create view claim_oppening_to_settlement_date_avg as 
select p.policy_type as type_of_policy,  avg(c.settlement_date - c.claim_date )::decimal(6,2) avg_number_of_days
from claims c left join policies p on c.policyid = p.policyid
where  c.settlement_date is not null
group by p.policy_type;


/* 
    present claims with a  amount significantly lower than the covered by the policy, where 
    its value is greater than 12% of the covered amount and less than  45% of the covered amount 
 */
create view siginificant_low_amount_claims
select cl.claimid , p.policyid , p.coverage_amount, cl.claim_amount
from claims cl inner join policies p 
on cl.policyid = p.policyid
where (cl.claim_amount > p.coverage_amount * 0.12) and
 (cl.claim_amount < p.coverage_amount * 0.45 );