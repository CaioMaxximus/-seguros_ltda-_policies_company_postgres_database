
/*
    Function to calculate the balance of not paid policy premiums, for a given customer id.

    Parameters :
        customer_id(INT) - The ID of the customer for whom unpaid premiums will be calculated.        
    
    Details :
        The function retrieves all the policies from a customer and all the payments made for these 
        policies, summing the total values of payments for each policy and using the number of months
        from the start of policy contract until the current date to multiply by the premium value of each policy,
        resulting in the values, the total paid until the present date , and the total that must be paid,
        the diffennce results in value that the customer owes.
*/

create or replace  function get_not_paid_active_premiums_from_customer_by_policy(customer_id int)
returns table(
    policyid int,
    missing_payment decimal
) as
$$
declare

    customer_id int := get_not_paid_active_premiums_from_customer_by_policy.customer_id;
begin
    return query
    with pol as (
        select * from policies
        where customerid = customer_id and 
        CURRENT_DATE between start_date and end_date)
        
    select  po.policyid as policy_id , 
        ((po.premium_amount) * (EXTRACT(year from age(current_date , po.start_date)) * 12 +
            EXTRACT(month from age(current_date ,  po.start_date)))::decimal) - 
        coalesce(sum(p.payment_amount)) as  missing_payment
        FROM pol po left join  payments p  on p.policyid = po.policyid
        group by po.policyid,po.premium_amount , po.start_date;
end;
$$ LANGUAGE plpgsql;


/*
    Work in this logic..
*/

create or replace function get_non_renewed_expired_policies_until_date(date_e date)
returns table(
    id_policy int,
    expire_date date
)
as 
$$
declare

target_date date := get_non_renewed_expired_policies_until_date.date_e;
begin
    return query
    
    select p.policyid , p.end_date
    from policies p
    where target_date > p.end_date and 
        p.customerid not in 
        
        (select pl.customerid
            from policies pl
            where target_date < pl.end_date );
end;
$$ LANGUAGE plpgsql;




/*
    Function to get clients with frequent claims in the n previous months..

    Parameters :
        months(INT) - The number of previus  months that the function will start looking for claims   
    
    Details :
        The function start in searching claims based in the current date minus the number of months parameter.
        The max values of claims is based in a max number of claims per year(12 months), in the variable
        critical_number; this calculation is made to be proportional to the number of previus months window and 
        the number of policies from the cliente, as the interval grows the critical number gets bigger.
    Example :
        In a 15 months interval the critical number will be 1.65/12  ~= 0.1375, if a customer has 3 policies
        with 1,2,1 claim for each one, the value will be: ( 4/3 / 15), the number of claims for all customer 
        polices, multiplied by the size of the interval divided by 12, and all of this divided by the number of policies: 3.
*/

create or replace function get_customers_with_frequent_claims(months int)
returns table(
    id_customer int,
    num_claims bigint
)as 
$$
declare
    n_last_months int := get_customers_with_frequent_claims.months;
    critical_number decimal := (1.65  * n_last_months / 12);
begin
    if n_last_months < 12 then
        critical_number := 1.65 / 12 * (12 - 1 - n_last_months);
    end if;
    return query
    with customer_selected as (
        select p.customerid, count(cl.claimid) as num_claims , count(distinct(p.policyid)) as num_policies
        from claims cl inner join policies p
        on p.policyid = cl.policyid
        where claim_date >= (current_date - INTERVAL '1 month' * n_last_months)
        group by p.customerid
    )
    select cs.customerid, cs.num_claims, cs.num_policies
    from customer_selected cs
    where ((cs.num_claims::DECIMAL /  cs.num_policies) * n_last_months / 12 ) > critical_number;
    
end;
$$ LANGUAGE plpgsql;

/*

    Function to count to total covered by the policies in a date range grouped by the policy type.
    
    Parameters:
        start_date (date) - The minimum date that the policy must start.
        end_date (date) - The maximum date that the policy must ends.


    Details: The function searchs all the policies in the desired date interval, sum his coverage values
    grouping by its policy type.
*/

create or replace function get_total_coverage_amount_per_policy_type_in_interval(start_date date , end_date date)
returns table(
    policy_type VARCHAR,
    total_amount DECIMAL
)
as
$$
declare
    s_date date := get_total_coverage_amount_per_policy_type_in_interval.start_date;
    e_date date := get_total_coverage_amount_per_policy_type_in_interval.end_date;
begin
    return query
        select  p.policy_type, sum(coverage_amount) 
        from policies p 
        where p.start_date >= s_date and p.end_date <= e_date
        group by p.policy_type;
end;
$$ LANGUAGE plpgsql;


/*
    Auxiliar function  to the function : agents_comissions_payed_total,
    returns a json formated data containing the agents comissions for 
    the first and remaining years for each policy type .

*/

CREATE OR REPLACE FUNCTION get_commissions()
RETURNS JSONB AS $$
DECLARE
    commissions JSONB := '{}';
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT policy_type, first_year, remaining_years 
        FROM commission_agent_policy 
    LOOP
        commissions := jsonb_set(
            commissions,
            ARRAY[rec.policy_type::text], 
            jsonb_build_object('first_year', rec.first_year, 'remaining_years', rec.remaining_years),
            true
        );
    END LOOP;

    RETURN commissions;
END;
$$ LANGUAGE plpgsql;



/*
    Function to calculate the total amount paid for an agent, until the final of the contract,
    based on the policies him manages.
    
    Parameters:
        id_agent(INT) - the agent id
    Details:
        The function takes the agent id and select all the policies he manages, counting its number of 
        months, and using the get_commissions() function to calculate the comission for each type of policy in
        the first and in the remaining years.

*/


create or replace function agents_comissions_payed_total(id_agent int)
returns decimal(10,2)
as
$$
    declare 
        agent_id int := agents_comissions_payed_total.id_agent;
        total_comissions decimal:=0 ;
        total_months int;
        type_p varchar;
        premium_amount decimal;
        commissions JSONB  := get_commissions(); ;
        currently_y_commission decimal;
    begin
        for total_months, type_p , premium_amount in 
        SELECT 
            EXTRACT(YEAR FROM AGE(p.end_date ,p.start_date )) * 12 + 
            EXTRACT(MONTH FROM AGE( p.end_date,p.start_date)) AS total_months,
            p.policy_type as p_type,
            p.premium_amount as premium_amount
            from policies p 
            where p.policyid in (
                select pa.policyid from 
                policy_agents pa
                where pa.agentid = agent_id
            )
        loop
            if total_months > 12 then
                total_comissions := total_comissions + 
                    12 * premium_amount* (commissions->type_p->>'first_year')::DECIMAL;
                total_comissions := total_comissions + 
                    (total_months - 12 ) * premium_amount * (commissions->type_p->>'remaining_years')::DECIMAL;
            else
                total_comissions := total_comissions + 
                    total_months * premium_amount * (commissions->type_p->>'first_year')::DECIMAL;
            end if;
        end loop;

        return total_comissions::DECIMAL(10,2);
    end;
$$ 
LANGUAGE plpgsql;




/*
    Function to verify the payments conformity with the policy premium amount 

    Parameters:
        id(INT) - the policy id
    Details:
        Count all the payments from a policy from the start to end of the contract, 
        or until the present day, if its not finishid yet. Comparing the sum of 
        payments with the number of months that passed multiplied by the premium amount.
*/


create or replace function verify_policy_payments(id int)
returns table(
    total_missing decimal, 
    total_paid decimal
)
as 
$$
declare
    id_policy int := verify_policy_payments.id;
    passed_months int;
    dates record;
begin 

    select p.start_date, p.end_date 
    into dates
    from policies p
    WHERE p.policyid = id_policy; 


    if current_date < dates.end_date then
        passed_months := EXTRACT(year from age(current_date , dates.start_date)) * 12 +
            EXTRACT(month from age(current_date , dates.start_date));
    else 
        passed_months := EXTRACT(year from age(dates.end_date , dates.start_date)) * 12 +
            EXTRACT(month from age(dates.end_date , dates.start_date));
    end if;

    RAISE NOTICE 'The value of passed_months_total is: %', passed_months;


    return query
    with values_t as (select p.premium_amount as premium,
                (
                select sum(pa.payment_amount)
                    from payments pa
                    where pa.policyid = id_policy
                ) as payed_total
            from policies p
            where p.policyid = id_policy )
    select (passed_months * vt.premium - vt.payed_total)::decimal as payment_missing,
        vt.payed_total as total_payed
        from values_t vt;
    end;
$$ 
LANGUAGE plpgsql;



/* 
    function to list all policies managed by an specific agent

    Parameters:
        id(INT) : agent id
    Details:
        The function selects all the policies from and specific agent using the agent_policy 
        table.
*/

create or replace function view_policies_by_agent(id int)
returns table(
    policy_id int,
    premium_amount decimal,
    coverage_amount decimal,
    start_date  date,
    end_date date
)
as
$$
declare
    id_agent int := view_policies_by_agent.id
begin
return query
    select policyid as id, premium_amount as premium,coverage_amount as  coverage,
    start_date as st_d , end_date as ed_d
    from policies 
    where policyid in ( select policyid from
    policy_agents where agentid = id_agent);
end;
$$ 
LANGUAGE plpgsql;