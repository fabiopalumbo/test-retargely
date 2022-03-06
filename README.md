# test-retargely
test for retargely

# DevOps Challenge

## Index

* [Instructions](#instructions)
* [Proposed Architecture](#proposed-architecture)
* [Terraform Plan](#terraform-plan-terratest)
* [CICD - Automation](#cicd-automation-bonus)
* [Observability](#observability-bonus)
* [Permissions](#permissions-bonus)
* [Best Practices](#best-practices-bonus)
* [Disaster Recovery Plan](#disaster-recovery-plan-bonus)
* [Compliance](#compliance-bonus)
* [Budget](#budget-bonus)


## Instructions

<details>
<summary><b>Test Details</b></summary>

---

1- Build an infra in Terraform with the following requirements so that it can be executed by a client

Everything with HA and secured (principle of least possible permission).

Only 1 Network(VPC) of 4096 ips.

Only 4 Subnets of 256 ips (two public, two private with Internet access)

A bucket with a file called text.txt and contains the string "Hello World."

Entry point, an APIGW that sends traffic to Lambda.

Application, a Lambda that returns the content of the file texto.txt. The code can be in any language.

TF code must be delivered to a Git repository

The Git repository should contain a README that explains step by step how to run the terraform code and how to test the API remotely.

2 - Explain: how would the lambda code deploy flow be for someone who is not a devop and does not have access to Terraform, how would you automate it?

3 - Explain:

  a-What resources would you monitor?

  b-What values ​​of the resources would you monitor?

  c-What values ​​would you put an alert on?

4 - Explain: With what tool and how would you implement the monitoring/alerts.

</details>

## FAQ

<details>
<summary>User / Permissions Migration</summary>

```
Are the users using auth/authentication federated service? SSO auth?

User’s apply through filling out forms without the necessity of creating an account with the bank (it is open to anyone)
so there should be no auth involved.
In the future we might incorporate federated auth that will allow us to fill out some information that we currently
request to users. So any prep work for the future would be great.
```
</details>


## Proposed Architecture

The following is ***a proposal***. Therefore, the infrastructure may have the required resources and correlation between them, but is in no way ready for usage.  It works as some extent. Lambda functions needs to be fine-tuned, workflows needs to be tested, data stream needs to be tested, the processing application doesn't exist. Batch configuration needs to be improved.  This is an example that is 70% completed, not intented for application. 

![alt text](/images/proposed_diagram.png "Proposed diagram")

The proposed solution performs the following acctions. 

1. API GW will be consumed by End User at certain endpoint.
2. API GW will be directly forwarding the data to a Lambda.
3. Lambda will retrieve the information of a file stored in a s3 bucket. 

## Requirements

* An active AWS account
* AWS Keys
* Terraform => https://learn.hashicorp.com/tutorials/terraform/install-cli
* AWS CLI => https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

## Constrains

* CICD account with AWS privileges to run Terraform
* Secrets stored in the Github repository in order to the pipeline to dont fail
* Local environment (.env) vars for test deplolyment

# Process for local testing

1. Use the `env.template` file to create the `.env` file.
2. Populate the `.env` file with your AWS access KEYs and selected Region.
3. Execute `source .env`.
4. Execute `terraform plan`
5. Execute `terraform apply`

## Terraform plan / Terratest

<details>
<summary>Summary</summary>
  
```
(WIP)
```
</details>

## Observability

We will consider the following metrics

* Scalability
* Reliability
* Availability
* Latency
* Fexibility 

<details>
<summary>Summary</summary>
  
Scalability
* What: Data storage availability, Processing compute power, Low concurrecy limits. 
* Why: Direct impact on customer experience, Reduced time and cost. 

Reliability
* What: S3 redundancy and failover, Cero downtime under Availability zone. 
* Why: Business process persistance, direct customer experience. 

Availability
* What: Multi zone enabled, Zero downtime under Availability zone failure. 
* Why: Business process persistance, direct customer experience. 

Latency
* What: API GW call and efficiency
* Why: Direct impact on customer experience, Reduced time and cost.

Fexibility
* What: Event driven architecture easy enough modifications and behaviors. Lambda functions and events. 
* Why: Bussiness logic dependant. If more Scalability, Availability is needed, it can be configured and added if needed. 


</details>

## Monitoring and ALerting

(WIP)

## CICD Automation

(Explnatino WIP)

Using a CI/CD tool (i.e. Github Actions) 
1. Setup a build process to create a docker image of just the batch processing part of the monolithic application.
2. Push the resulting image to AWS ECR.
3. Update the Batch Job Definition with the new image tag. 

The next execution will use the newly created image. 

## Permissions 

All infrastructure authentication is controlled by IAM Roles. The FAQs state that the users do not required authentication. 

Wew will use the principle of Least Priviledge 

1. We will create specific IAM Roles for Lambda to only access the Resource of the S3 bucket
2. S3 Bucket will be retricted and with ACL configured
3. Bussiness Logic will be deployed in the private layer


## Disaster Recovery Plan

(RTO) (RPO)

## Compliance

(WAF) (GDPR)


## Migration

There is no real benefit of creating a new migration strategy if there is already one that is proven to work. I recommend using AWS DMS  

What Migration Strategy would you choose?

AWS DMS -  AWS Database Migration Service. 

https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/migrate-an-on-premises-oracle-database-to-amazon-rds-for-oracle.html

Code modification to incorporate the AWS infrastructure replacing some code logic that might be in place that performs steps that are already taken care by the AWS cloud infra. 

## App Migration Plan
The application is monolithic, therefore, some of the components of the application will be replaced by the cloud infrastructure. The main component of the application we required is the actual batch processing piece, which is the one that will be used by the batch instances. 

1. Isolate the data transformer - the one that preformats the forms data into something that the batch process is able to handle. 
2. Use the data transformer to create a lambda function to preformat data at the AWS Kinesis stream step. (Lambda function is provided for that purpose)
3. Isolate the batch processing code. 
4. Create a Dockerfile with all the required dependencies for the batch process code to run. 
5. Modify the batch process code to consume and AWS SQS with the metadata of the user filled data from the forms. 
6. Modify the batch process code to pull the required form data using the metadata pulled from AWS SQS.
7. Modify the batch process code to process the preformated data stored in AWS Redshift. 
8. Keep the code to update the processed data in to the Oracle DB. 
9. Push the new Docker image to the AWS Batch ECR repository. 

## Database Migration Plan

Using AWS DMS.

At the on-premise Oracle DB
1. Enable database-level supplemental logging -> `ALTER DATABASE ADD SUPPLEMENTAL LOG DATA;`
2. Enable identification key supplemental logging -> `ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;`
3. Add supplemental logging on a subset of columns in a table, -> `ALTER TABLE table_name ADD SUPPLEMENTAL LOG GROUP example_log_group (ID,NAME) ALWAYS;`
4. Configure a database account to be used by AWS DMS
```
CREATE SESSION
SELECT ANY TRANSACTION
SELECT on V_$ARCHIVED_LOG
SELECT on V_$LOG
SELECT on V_$LOGFILE
SELECT on V_$DATABASE
SELECT on V_$THREAD
SELECT on V_$PARAMETER
SELECT on V_$NLS_PARAMETERS
SELECT on V_$TIMEZONE_NAMES
SELECT on V_$TRANSACTION
SELECT on ALL_INDEXES
SELECT on ALL_OBJECTS
SELECT on ALL_TABLES
SELECT on ALL_USERS
SELECT on ALL_CATALOG
SELECT on ALL_CONSTRAINTS
SELECT on ALL_CONS_COLUMNS
SELECT on ALL_TAB_COLS
SELECT on ALL_IND_COLUMNS
SELECT on ALL_LOG_GROUPS
SELECT on SYS.DBA_REGISTRY
SELECT on SYS.OBJ$
SELECT on DBA_TABLESPACES
SELECT on ALL_TAB_PARTITIONS
SELECT on ALL_ENCRYPTED_COLUMNS
* SELECT on all tables migrated
```
5. Capture and apply changes (CDC)
```
EXECUTE on DBMS_LOGMNR
SELECT on V_$LOGMNR_LOGS
SELECT on V_$LOGMNR_CONTENTS
LOGMINING /* For Oracle 12c and higher. */
* ALTER for any table being replicated (if you want DMS to add supplemental logging)
```


## Budget

Calculation Report
![alt text](/images/Estimate.png "AWS price estimation")

The above was generated using https://calculator.aws/#/.  Is an approximation for heavy usage on the 100 million requests per month. 





