
/* Identify  customers with more than one active polices and its total number*/
(select  c.customerid as customer_id, count(p.policyid) as policies 
from policies p right join customers c on p.customerid = c.customerid
where current_date between p.start_date  and p.end_date
group by c.customerid
having count(p.policyid) > 1
);

/* Calculate the total amount of awards paids for each client for its all policies*/
(with claims_settled as (select claimid , policyID ,settlement_amount from 
claims where claim_status = 'Settled')
select c.first_name as name , c.ssn as ssn , sum(cl.settlement_amount) as total_paid
from  claims_settled cl 
inner join policies p on cl.policyid  = p.policyid 
inner join customers c on c.customerid = p.customerid
group by c.customerid);

/* 
Find all claim where the claim_amount exceeds a certain value, 
and the associated policy cover the value
*/

(select c.claimid as id_claim ,  p.policyid as id_policy, 
c.claim_amount  as "amount claimed" , p.coverage_amount as "amount covered"
from claims c inner join  policies p on c.policyid = p.policyid
where c.claim_amount > 40000  and p.coverage_amount > c.claim_amount);

/* Find all policies with no payments registered*/
(select policyid
from policies 
where policyid not in (select policyid from payments));

/* list all policies managed by an specific agent*/
(select policyid as id, coverage_amount as coverage, premium_amount as payment 
from policies 
where policyid in ( select policyid from
policy_agents where agentid = 2));


/* counting the number of claim for each type of policy*/

(select p.policy_type  as "policy type" , count(claimid) as "number of claims"
from policies p inner join claims c on p.policyid = c.policyid
group by p.policy_type
order by count(claimid) desc);

/* Indentify clients with any claim ***/

(select c.ssn , c.first_name from customers c
where c.customerid not in (select p.customerid from 
policies p inner join claims cl on p.policyid = cl.policyid));


/* count the number of claims per year grouped by the  type of policy*/


( 
    with claim_year as 
    (select policyid , date_part('year' ,claim_date ) as year from claims)
    select p.policy_type as "type of policy" , c.year as year, count(c.year)
    from policies p inner join claim_year c on p.policyid = c.policyid
    group by p.policy_type , c.year
    order by count(c.year) desc
);

/* policies with pending payments in previous month*/
(
    select policyid from policies
    where current_date between start_date and end_date
    and policyid not in (
    select policyid from payments 
    where EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 MONTH') = EXTRACT(MONTH FROM payment_date) and 
    EXTRACT(year FROM CURRENT_DATE) = EXTRACT(year FROM payment_date))

);