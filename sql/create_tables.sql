
CREATE TABLE Employees (
    employeeID int   NOT NULL,
    departamentID int   NOT NULL,
    name varchar(50)   NOT NULL,
    salary numeric(10,2)   NOT NULL,
    born_date date   NOT NULL,
    ssn varchar(9)   NOT NULL,
    CONSTRAINT pk_Employees PRIMARY KEY (
        employeeID
     )
);

CREATE TABLE Departaments (
    departamentID int   NOT NULL,
    name varchar(50)   NOT NULL,
    manager int   NOT NULL,
    CONSTRAINT pk_Departaments PRIMARY KEY (
        departamentID
     )
);

CREATE TABLE Customers (
    customerid INT   NOT NULL,
    first_name VARCHAR(30)   NOT NULL,
    last_name VARCHAR(30)   NOT NULL,
    ssn VARCHAR(9)  NOT NULL,
    date_of_birth DATE  NOT NULL,
    address VARCHAR(255)   NOT NULL,
    phone_number VARCHAR(15)  NOT NULL,
    email VARCHAR(255)   NOT NULL,
    CONSTRAINT pk_Customers PRIMARY KEY (
        customerid
     )
);

CREATE TABLE Policies (
    policyid INT   NOT NULL,
    customerid INT   NOT NULL,
    policy_number VARCHAR(50)   NOT NULL,
    policy_type VARCHAR(50)   NOT NULL,
    start_date DATE   NOT NULL,
    end_date DATE   NOT NULL,
    coverage_amount DECIMAL(10,2)   NOT NULL,
    premium_amount DECIMAL(10,2)   NOT NULL,
    CONSTRAINT pk_Policies PRIMARY KEY (
        policyid
     )
);

CREATE TABLE Payments (
    paymentID INT   NOT NULL,
    policyID INT   NOT NULL,
    payment_date DATE   NOT NULL,
    payment_amount DECIMAL(10,2)   NOT NULL,
    payment_method VARCHAR(50)   NOT NULL,
    CONSTRAINT pk_Payments PRIMARY KEY (
        paymentID
     )
);

CREATE TABLE Claims (
    claimID INT   NOT NULL,
    policyID INT   NOT NULL,
    claim_number VARCHAR(50)   NOT NULL,
    claim_date DATE   NOT NULL,
    claim_status VARCHAR(50)   NOT NULL,
    claim_amount DECIMAL(10,2)   NOT NULL,
    settlement_amount DECIMAL(10,2)   NOT NULL,
    CONSTRAINT pk_Claims PRIMARY KEY (
        claimID
     )
);

CREATE TABLE Agents (
    agentID INT   NOT NULL,
    first_name VARCHAR(100)  NOT NULL,
    last_name VARCHAR(100)  NOT NULL,
    license_number VARCHAR(20)   NOT NULL,
    phone_number VARCHAR(15)   NOT NULL,
    email VARCHAR(255)   NOT NULL,
    CONSTRAINT pk_Agents PRIMARY KEY (
        agentID
     )
);

CREATE TABLE Policy_Agents (
    policy_agent_id INT   NOT NULL,
    policy_id INT   NOT NULL,
    agent_id INT   NOT NULL,
    CONSTRAINT pk_Policy_Agents PRIMARY KEY (
        policy_agent_id
     )
);

ALTER TABLE Departaments ADD CONSTRAINT fk_Departaments_manager FOREIGN KEY(manager)
REFERENCES Employees (employeeID);

ALTER TABLE Policies ADD CONSTRAINT fk_Policies_customer_id FOREIGN KEY(customerid)
REFERENCES Customers (customerid);

ALTER TABLE Payments ADD CONSTRAINT fk_Payments_policy_id FOREIGN KEY(policyid)
REFERENCES Policies (policyid);

ALTER TABLE Claims ADD CONSTRAINT fk_Claims_policy_id FOREIGN KEY(policyid)
REFERENCES Policies (policyid);

ALTER TABLE Policy_Agents ADD CONSTRAINT fk_Policy_Agents_policy_id FOREIGN KEY(policyid)
REFERENCES Policies (policyid);

ALTER TABLE Policy_Agents ADD CONSTRAINT fk_Policy_Agents_agent_id FOREIGN KEY(agentid)
REFERENCES Agents (agentid);
