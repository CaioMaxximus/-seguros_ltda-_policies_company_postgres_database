
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