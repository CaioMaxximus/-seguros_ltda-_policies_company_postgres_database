-- Insert Departments
INSERT INTO Departments (departamentID, name, manager) VALUES
(1, 'Sales', NULL),
(2, 'Claims', NULL),
(3, 'Underwriting', NULL);

INSERT INTO commission_agent_policy(policy_type , first_year , remaining_years) VALUES
('Auto', 0.12,0.06),
('Home', 0.15,0.08),
('Health', 0.25,0.8),
('Life',0.66, 0.09);

-- Insert Employees (include IDs for the department managers)
INSERT INTO Employees (employeeID, departamentID, name, salary, born_date, ssn) VALUES
(1, 1, 'Alice Johnson', 70000.00, '1985-03-10', '111223333'),
(2, 2, 'Bob Smith', 80000.00, '1979-06-25', '222334444'),
(3, 3, 'Charlie Brown', 75000.00, '1983-12-15', '333445555');

-- Update Departments to reference the managers
UPDATE Departments SET manager = 1 WHERE departamentID = 1;
UPDATE Departments SET manager = 2 WHERE departamentID = 2;
UPDATE Departments SET manager = 3 WHERE departamentID = 3;

-- Insert Customers
INSERT INTO Customers (customerid, first_name, second_name, ssn, date_of_birth, phone_number, email) VALUES
(1, 'John', 'Doe', '123456789', '1980-01-15', '555-1234', 'john.doe@example.com'),
(2, 'Jane', 'Smith', '987654321', '1990-05-25',  '555-5678', 'jane.smith@example.com'),
(3, 'Mike', 'Johnson', '567894321', '1975-03-10','555-6789', 'mike.johnson@example.com');
(4, 'Cristian', 'Martines', '432894321', '1989-03-13','555-7399', 'Cristian.Martines@example.com');

-- Insert Policies
INSERT INTO Policies (policyid, customerid, policy_number, policy_type, start_date, end_date, coverage_amount, premium_amount) VALUES
(1, 1, 'POL1001', 'Auto', '2023-01-01', '2024-01-01', 20000.00, 120.00), 
(2, 1, 'POL1002', 'Home', '2023-01-01', '2024-01-01', 150000.00, 180.00), 
(3, 2, 'POL1003', 'Health', '2023-02-01', '2024-02-01', 50000.00, 350.00), 
(4, 3, 'POL1004', 'Life', '2023-05-12', '2024-12-01', 120000.00, 45.00), 
(5, 3, 'POL1005', 'Auto', '2023-02-11', '2025-03-25', 180000.00, 160.00),
(6, 3, 'POL1006', 'Home', '2023-04-21', '2024-12-30', 270000.00, 250.00),
(7, 2, 'POL1007', 'Home', '2023-03-15', '2025-12-30', 370000.00, 320.00),
(8, 2, 'POL1008', 'Auto', '2023-02-10', '2025-12-30', 170000.00, 140.00),
(9, 2, 'POL1009', 'Health', '2023-01-19', '2025-12-30', 200000.00, 400.00),
(10, 4, 'POL1010', 'Health', '2023-05-11', '2026-01-30', 170000.00, 390.00);

-- Insert Payments
INSERT INTO Payments (paymentID, policyID, payment_date, payment_amount, payment_method) VALUES
(1, 1, '2023-01-15', 500.00, 'Credit Card'),
(2, 2, '2023-02-15', 600.00, 'Credit Card'),
(3, 2, '2023-03-15', 600.00, 'Bank Transfer'),
(4, 3, '2023-02-05', 700.00, 'Debit Card'),
(5, 4, '2023-03-10', 900.00, 'Credit Card');

DO $$
DECLARE
    rec RECORD;
    payment_date DATE;
    current_date_ DATE := current_date;
BEGIN
    FOR rec IN
        SELECT policyid, start_date, end_date, premium_amount
        FROM policies
    LOOP
        FOR payment_date IN
            SELECT generate_series(rec.start_date, rec.end_date, INTERVAL '1 month')
        LOOP
            if payment_date < current_date_ then
                INSERT INTO payments (policyID, payment_date, payment_amount, payment_method)
                VALUES (rec.policyid, payment_date, rec.premium_amount, 'Credit Card');
            end if;
        END LOOP;
    END LOOP;
END $$;

-- Insert Claims
INSERT INTO Claims (claimID, policyID, claim_number, claim_date, claim_status, claim_amount, settlement_amount) VALUES
(1, 1, 'CLM2001', '2023-05-01', 'Settled', 5000.00, 4500.00),
(2, 2, 'CLM2002', '2023-06-15', 'Pending', 3000.00, 0.00),
(3, 3, 'CLM2003', '2023-07-20', 'Settled', 2000.00, 2000.00),
(4, 4, 'CLM2004', '2023-08-05', 'Rejected', 10000.00, 0.00),
(5, 8, 'CLM2005', '2023-03-10', 'Settled', 100000.00, 80000.00),
(6, 9, 'CLM2006', '2023-06-16', 'Settled', 30000.00, 15000.00),
(7, 1, 'CLM2006', '2022-05-13', 'Settled', 400.00, 400.00),
(8, 3, 'CLM2008', '2023-08-11', 'Settled', 3000.00, 2500.00),
(9, 2, 'CLM2009', '2023-03-23', 'Settled', 300.00, 300.00),
(10, 3, 'CLM2010', '2023-01-18', 'Settled', 4000.00, 3700.00),
(11, 3, 'CLM2011', '2024-06-02', 'Pending', 2000.00, 0);


-- Insert Agents
INSERT INTO Agents (agentID, first_name, second_name, license_number, phone_number, email) VALUES
(1, 'Alice', 'Brown', 'A123456', '555-8765', 'alice.brown@example.com'),
(2, 'Bob', 'Davis', 'B654321', '555-4321', 'bob.davis@example.com');

-- Associate Agents with Policies
INSERT INTO Policy_Agents (policy_agent_id, policyid, agentid) VALUES
(1, 1, 1),
(2, 2, 1),
(3, 3, 2),
(4, 4, 2);
-- adicionar mais agentes com pólices


