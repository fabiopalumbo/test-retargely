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


## Questions
<details>
<summary><b>How would the lambda code deploy flow be for someone who is not a devop and does not have access to Terraform, how would you automate it?</b></summary>

---
We will create a CICD Pipeline using Github Actions, whenever the python code of the Lambda gets updated, the CICD will redeploy the lambda code to update to the latest version.
</details>

<details>
<summary><b>What resources would you monitor</b></summary>

---
We will monitor APIGW and Lambda resources, more information can be found Alerts section.

</details>

<details>
<summary><b>What values ​​of the resources would you monitor?</b></summary>

---
For Lambda we will review invocations metrics, concurrency, utilization and performance.
For APIGW we will monitor Erro codes as 4XX and 5XX, Latency and also service health status (API calls)
</details>

<details>
<summary><b>What values ​​would you put an alert on?</b></summary>

---
We will define alarm/threshold for Lambda regarding
```
functionErrors:
        period: 600
functionInvocations:
        threshold: 10
        period: 600
functionPerformance:
        metric: duration
        threshold: 200
        statistic: Average
        period: 300
        evaluationPeriods: 1
        datapointsToAlarm: 1
        comparisonOperator: GreaterThanThreshold
```

We will define alarm/threshold for APIGW regarding
```
latency_threshold_p95 - 95th percentile latency, which represents typical customer experienced latency figures
        threshold: 1000
        period: 5
latency_threshold_p99 - 99th percentile latency, represents the worst case latency that customers experience
        threshold: 1000
        period: 5
fourRate_threshold - HTTP 400 errors reported by the endpoint
        threshold: 0.02
        period: 5
fiveRate_threshold - HTTP 500 internal server errors reported by the endpoint
        threshold: 0.02
        period: 5               
```

</details>

<details>
<summary><b>With what tool and how would you implement the monitoring/alerts.</b></summary>

---
We are going to deploy monitoring and alerts with Cloudwatch that is integrated to Lambda and ApiG metrics, all will be deployed using terraform.
</details>

## FAQ

## Proposed Architecture

The following is ***a proposal***. Therefore, the infrastructure may have the required resources and correlation between them, but is in no way ready for usage.  It works as some extent. Lambda functions needs to be fine-tuned, workflows needs to be tested, data stream needs to be tested, the processing application doesn't exist. Batch configuration needs to be improved.  This is an example that is 70% completed, not intented for application. 

![alt text](/images/proposed_diagram.png "Proposed diagram")

The proposed solution performs the following acctions. 
```
1. API GW will be consumed by End User at certain endpoint.
2. API GW will be directly forwarding the data to a Lambda.
3. Lambda will retrieve the information of a file stored in a s3 bucket. 
```
## Requirements

* An active AWS account
* AWS Keys
* Terraform => https://learn.hashicorp.com/tutorials/terraform/install-cli
* AWS CLI => https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

## Constrains

* CICD account with AWS privileges to run Terraform
* Secrets stored in the Github repository in order to the pipeline to dont fail
* An S3 Bucket to store the backend of the Terraform code
* Local environment (.env) vars for test deployment

# Process for local testing

1. Use the `env.template` file to create the `.env` file.
2. Populate the `.env` file with your AWS access KEYs and selected Region.
3. Execute `source .env`.
4. Change Backend to `local {}`
5. Execute `terraform init`
6. Execute `terraform plan`

## Terraform plan / Terratest

<details>
<summary>Summary</summary>
  
```
terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

module.vpc.data.aws_vpc_endpoint_service.s3[0]: Refreshing state...
module.vpc.data.aws_vpc_endpoint_service.apigw[0]: Refreshing state...
module.text_loader[0].data.aws_iam_policy_document.assume_role[0]: Refreshing state...
module.apigw.data.aws_region.current: Refreshing state...
module.text_loader[0].data.aws_caller_identity.current: Refreshing state...
module.text_loader[0].data.aws_region.current: Refreshing state...
module.apigw.data.aws_caller_identity.current: Refreshing state...
data.aws_region.current: Refreshing state...
data.aws_caller_identity.current: Refreshing state...
module.apigw.data.aws_iam_policy_document.apigw_assume_role: Refreshing state...
data.aws_availability_zones.available: Refreshing state...
module.apigw.data.aws_iam_policy_document.api_gw_access_s3_assume_policy: Refreshing state...
data.aws_iam_policy_document.text_lambda_loader[0]: Refreshing state...

------------------------------------------------------------------------

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # aws_iam_policy.text_lambda_loader[0] will be created
  + resource "aws_iam_policy" "text_lambda_loader" {
      + arn         = (known after apply)
      + description = "Text loader lambda policy"
      + id          = (known after apply)
      + name        = (known after apply)
      + path        = "/"
      + policy      = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "s3:GetObjectAcl",
                          + "s3:GetObject",
                        ]
                      + Effect   = "Allow"
                      + Resource = [
                          + "arn:aws:s3:us-east-1:476795228417:{var.bucket}/*",
                          + "arn:aws:s3:us-east-1:476795228417:{var.bucket}",
                        ]
                      + Sid      = ""
                    },
                  + {
                      + Action   = "s3:ListAllMyBuckets"
                      + Effect   = "Allow"
                      + Resource = "*"
                      + Sid      = ""
                    },
                  + {
                      + Action   = [
                          + "s3:ListBucket",
                          + "s3:GetBucketLocation",
                        ]
                      + Effect   = "Allow"
                      + Resource = "arn:aws:s3:us-east-1:476795228417:{var.bucket}"
                      + Sid      = ""
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + policy_id   = (known after apply)
      + tags_all    = (known after apply)
    }

  # aws_security_group.endpoint_securitygroup will be created
  + resource "aws_security_group" "endpoint_securitygroup" {
      + arn                    = (known after apply)
      + description            = "Allow VPC traffic"
      + egress                 = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + description      = ""
              + from_port        = 0
              + ipv6_cidr_blocks = [
                  + "::/0",
                ]
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "10.10.0.0/16",
                ]
              + description      = "Allow from VPC"
              + from_port        = 0
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "-1"
              + security_groups  = []
              + self             = false
              + to_port          = 0
            },
        ]
      + name                   = (known after apply)
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all               = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id                 = (known after apply)
    }

  # random_string.this will be created
  + resource "random_string" "this" {
      + id          = (known after apply)
      + length      = 4
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + result      = (known after apply)
      + special     = false
      + upper       = false
    }

  # module.apigw.aws_api_gateway_api_key.this will be created
  + resource "aws_api_gateway_api_key" "this" {
      + arn               = (known after apply)
      + created_date      = (known after apply)
      + description       = "Managed by Terraform"
      + enabled           = true
      + id                = (known after apply)
      + last_updated_date = (known after apply)
      + name              = "identifier-stream"
      + tags_all          = (known after apply)
      + value             = (sensitive value)
    }

  # module.apigw.aws_api_gateway_deployment.this will be created
  + resource "aws_api_gateway_deployment" "this" {
      + created_date  = (known after apply)
      + execution_arn = (known after apply)
      + id            = (known after apply)
      + invoke_url    = (known after apply)
      + rest_api_id   = (known after apply)
    }

  # module.apigw.aws_api_gateway_integration.this will be created
  + resource "aws_api_gateway_integration" "this" {
      + cache_namespace         = (known after apply)
      + connection_type         = "INTERNET"
      + credentials             = (known after apply)
      + http_method             = "PUT"
      + id                      = (known after apply)
      + integration_http_method = "POST"
      + passthrough_behavior    = (known after apply)
      + request_templates       = {
          + "application/json" = <<~EOT
                {
                    "DeliveryStreamName": $input.json('$.StreamName'),
                    "Record": {
                      "Data": "$util.base64Encode($input.json('$.Data'))"
                    }
                }
            EOT
        }
      + resource_id             = (known after apply)
      + rest_api_id             = (known after apply)
      + timeout_milliseconds    = 29000
      + type                    = "AWS"
      + uri                     = "arn:aws:apigateway:us-east-1:firehose:action/PutRecord"
    }

  # module.apigw.aws_api_gateway_integration_response.this will be created
  + resource "aws_api_gateway_integration_response" "this" {
      + http_method = "PUT"
      + id          = (known after apply)
      + resource_id = (known after apply)
      + rest_api_id = (known after apply)
      + status_code = "200"
    }

  # module.apigw.aws_api_gateway_method.this will be created
  + resource "aws_api_gateway_method" "this" {
      + api_key_required = true
      + authorization    = "NONE"
      + http_method      = "PUT"
      + id               = (known after apply)
      + resource_id      = (known after apply)
      + rest_api_id      = (known after apply)
    }

  # module.apigw.aws_api_gateway_method_response.this will be created
  + resource "aws_api_gateway_method_response" "this" {
      + http_method = "PUT"
      + id          = (known after apply)
      + resource_id = (known after apply)
      + rest_api_id = (known after apply)
      + status_code = "200"
    }

  # module.apigw.aws_api_gateway_resource.this will be created
  + resource "aws_api_gateway_resource" "this" {
      + id          = (known after apply)
      + parent_id   = (known after apply)
      + path        = (known after apply)
      + path_part   = "stream"
      + rest_api_id = (known after apply)
    }

  # module.apigw.aws_api_gateway_rest_api.this will be created
  + resource "aws_api_gateway_rest_api" "this" {
      + api_key_source               = "HEADER"
      + arn                          = (known after apply)
      + binary_media_types           = (known after apply)
      + created_date                 = (known after apply)
      + description                  = "identifier Endpoint"
      + disable_execute_api_endpoint = (known after apply)
      + execution_arn                = (known after apply)
      + id                           = (known after apply)
      + minimum_compression_size     = -1
      + name                         = "identifier-stream"
      + policy                       = (known after apply)
      + root_resource_id             = (known after apply)
      + tags                         = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "stream-api-identifier"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all                     = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "stream-api-identifier"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }

      + endpoint_configuration {
          + types            = [
              + "EDGE",
            ]
          + vpc_endpoint_ids = (known after apply)
        }
    }

  # module.apigw.aws_api_gateway_stage.this will be created
  + resource "aws_api_gateway_stage" "this" {
      + arn           = (known after apply)
      + deployment_id = (known after apply)
      + execution_arn = (known after apply)
      + id            = (known after apply)
      + invoke_url    = (known after apply)
      + rest_api_id   = (known after apply)
      + stage_name    = "stream"
      + tags_all      = (known after apply)
      + web_acl_arn   = (known after apply)
    }

  # module.apigw.aws_api_gateway_usage_plan.this will be created
  + resource "aws_api_gateway_usage_plan" "this" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + name     = "identifier-stream"
      + tags_all = (known after apply)

      + api_stages {
          + api_id = (known after apply)
          + stage  = "stream"
        }
    }

  # module.apigw.aws_api_gateway_usage_plan_key.this will be created
  + resource "aws_api_gateway_usage_plan_key" "this" {
      + id            = (known after apply)
      + key_id        = (known after apply)
      + key_type      = "API_KEY"
      + name          = (known after apply)
      + usage_plan_id = (known after apply)
      + value         = (known after apply)
    }

  # module.apigw.aws_iam_role.api_gw_role will be created
  + resource "aws_iam_role" "api_gw_role" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "apigateway.amazonaws.com"
                        }
                      + Sid       = ""
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = (known after apply)
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags_all              = (known after apply)
      + unique_id             = (known after apply)

      + inline_policy {
          + name   = (known after apply)
          + policy = (known after apply)
        }
    }

  # module.apigw.aws_iam_role_policy.api_gw_access_s3_policy will be created
  + resource "aws_iam_role_policy" "api_gw_access_s3_policy" {
      + id     = (known after apply)
      + name   = (known after apply)
      + policy = jsonencode(
            {
              + Statement = [
                  + {
                      + Action   = [
                          + "s3:GetObjectAcl",
                          + "s3:GetObject",
                        ]
                      + Effect   = "Allow"
                      + Resource = [
                          + "arn:aws:s3:us-east-1:476795228417:{var.bucket}/*",
                          + "arn:aws:s3:us-east-1:476795228417:{var.bucket}",
                        ]
                      + Sid      = ""
                    },
                  + {
                      + Action   = "s3:ListAllMyBuckets"
                      + Effect   = "Allow"
                      + Resource = "*"
                      + Sid      = ""
                    },
                  + {
                      + Action   = [
                          + "s3:ListBucket",
                          + "s3:GetBucketLocation",
                        ]
                      + Effect   = "Allow"
                      + Resource = "arn:aws:s3:us-east-1:476795228417:{var.bucket}"
                      + Sid      = ""
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + role   = (known after apply)
    }

  # module.apigw.random_string.this will be created
  + resource "random_string" "this" {
      + id          = (known after apply)
      + length      = 4
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + result      = (known after apply)
      + special     = false
      + upper       = false
    }

  # module.s3_bucket.aws_s3_bucket.this[0] will be created
  + resource "aws_s3_bucket" "this" {
      + acceleration_status         = (known after apply)
      + acl                         = "private"
      + arn                         = (known after apply)
      + bucket                      = (known after apply)
      + bucket_domain_name          = (known after apply)
      + bucket_regional_domain_name = (known after apply)
      + force_destroy               = true
      + hosted_zone_id              = (known after apply)
      + id                          = (known after apply)
      + region                      = (known after apply)
      + request_payer               = (known after apply)
      + tags                        = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all                    = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + website_domain              = (known after apply)
      + website_endpoint            = (known after apply)

      + versioning {
          + enabled    = false
          + mfa_delete = false
        }
    }

  # module.s3_bucket.aws_s3_bucket_public_access_block.this[0] will be created
  + resource "aws_s3_bucket_public_access_block" "this" {
      + block_public_acls       = false
      + block_public_policy     = false
      + bucket                  = (known after apply)
      + id                      = (known after apply)
      + ignore_public_acls      = false
      + restrict_public_buckets = false
    }

  # module.text_loader[0].data.aws_iam_policy_document.logs[0] will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "logs"  {
      + id   = (known after apply)
      + json = (known after apply)

      + statement {
          + actions   = [
              + "logs:CreateLogStream",
              + "logs:PutLogEvents",
            ]
          + effect    = "Allow"
          + resources = [
              + (known after apply),
              + (known after apply),
            ]
        }
    }

  # module.text_loader[0].aws_cloudwatch_log_group.lambda[0] will be created
  + resource "aws_cloudwatch_log_group" "lambda" {
      + arn               = (known after apply)
      + id                = (known after apply)
      + name              = (known after apply)
      + retention_in_days = 0
      + tags              = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all          = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
    }

  # module.text_loader[0].aws_iam_policy.logs[0] will be created
  + resource "aws_iam_policy" "logs" {
      + arn       = (known after apply)
      + id        = (known after apply)
      + name      = (known after apply)
      + path      = "/"
      + policy    = (known after apply)
      + policy_id = (known after apply)
      + tags_all  = (known after apply)
    }

  # module.text_loader[0].aws_iam_policy_attachment.logs[0] will be created
  + resource "aws_iam_policy_attachment" "logs" {
      + id         = (known after apply)
      + name       = (known after apply)
      + policy_arn = (known after apply)
      + roles      = (known after apply)
    }

  # module.text_loader[0].aws_iam_role.lambda[0] will be created
  + resource "aws_iam_role" "lambda" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "lambda.amazonaws.com"
                        }
                      + Sid       = ""
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = true
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = (known after apply)
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + unique_id             = (known after apply)

      + inline_policy {
          + name   = (known after apply)
          + policy = (known after apply)
        }
    }

  # module.text_loader[0].aws_iam_role_policy_attachment.additional_many[0] will be created
  + resource "aws_iam_role_policy_attachment" "additional_many" {
      + id         = (known after apply)
      + policy_arn = (known after apply)
      + role       = (known after apply)
    }

  # module.text_loader[0].aws_iam_role_policy_attachment.additional_many[1] will be created
  + resource "aws_iam_role_policy_attachment" "additional_many" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
      + role       = (known after apply)
    }

  # module.text_loader[0].aws_iam_role_policy_attachment.additional_many[2] will be created
  + resource "aws_iam_role_policy_attachment" "additional_many" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
      + role       = (known after apply)
    }

  # module.text_loader[0].aws_lambda_function.this[0] will be created
  + resource "aws_lambda_function" "this" {
      + architectures                  = (known after apply)
      + arn                            = (known after apply)
      + description                    = "Lambda function to asynchronous retrieve file from s3 bucket"
      + function_name                  = (known after apply)
      + handler                        = "text_loader.handler"
      + id                             = (known after apply)
      + invoke_arn                     = (known after apply)
      + last_modified                  = (known after apply)
      + memory_size                    = 128
      + package_type                   = "Zip"
      + publish                        = true
      + qualified_arn                  = (known after apply)
      + reserved_concurrent_executions = -1
      + role                           = (known after apply)
      + runtime                        = "python3.7"
      + signing_job_arn                = (known after apply)
      + signing_profile_version_arn    = (known after apply)
      + source_code_hash               = (known after apply)
      + source_code_size               = (known after apply)
      + tags                           = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all                       = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + timeout                        = 30
      + version                        = (known after apply)

      + environment {
          + variables = {
              + "DEBUG"     = "true"
              + "LOG_LEVEL" = "info"
            }
        }

      + tracing_config {
          + mode = (known after apply)
        }
    }

  # module.text_loader[0].random_string.this will be created
  + resource "random_string" "this" {
      + id          = (known after apply)
      + length      = 4
      + lower       = true
      + min_lower   = 0
      + min_numeric = 0
      + min_special = 0
      + min_upper   = 0
      + number      = true
      + result      = (known after apply)
      + special     = false
      + upper       = false
    }

  # module.vpc.aws_eip.nat[0] will be created
  + resource "aws_eip" "nat" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = (known after apply)
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-us-east-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-us-east-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc                  = true
    }

  # module.vpc.aws_eip.nat[1] will be created
  + resource "aws_eip" "nat" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = (known after apply)
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-us-east-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-us-east-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc                  = true
    }

  # module.vpc.aws_internet_gateway.this[0] will be created
  + resource "aws_internet_gateway" "this" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + tags     = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id   = (known after apply)
    }

  # module.vpc.aws_nat_gateway.this[0] will be created
  + resource "aws_nat_gateway" "this" {
      + allocation_id        = (known after apply)
      + connectivity_type    = "public"
      + id                   = (known after apply)
      + network_interface_id = (known after apply)
      + private_ip           = (known after apply)
      + public_ip            = (known after apply)
      + subnet_id            = (known after apply)
      + tags                 = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-us-east-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-us-east-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
    }

  # module.vpc.aws_nat_gateway.this[1] will be created
  + resource "aws_nat_gateway" "this" {
      + allocation_id        = (known after apply)
      + connectivity_type    = "public"
      + id                   = (known after apply)
      + network_interface_id = (known after apply)
      + private_ip           = (known after apply)
      + public_ip            = (known after apply)
      + subnet_id            = (known after apply)
      + tags                 = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-us-east-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-us-east-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
    }

  # module.vpc.aws_network_acl.private[0] will be created
  + resource "aws_network_acl" "private" {
      + arn        = (known after apply)
      + egress     = (known after apply)
      + id         = (known after apply)
      + ingress    = (known after apply)
      + owner_id   = (known after apply)
      + subnet_ids = (known after apply)
      + tags       = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all   = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id     = (known after apply)
    }

  # module.vpc.aws_network_acl.public[0] will be created
  + resource "aws_network_acl" "public" {
      + arn        = (known after apply)
      + egress     = (known after apply)
      + id         = (known after apply)
      + ingress    = (known after apply)
      + owner_id   = (known after apply)
      + subnet_ids = (known after apply)
      + tags       = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-public"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all   = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-public"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id     = (known after apply)
    }

  # module.vpc.aws_network_acl_rule.private_inbound[0] will be created
  + resource "aws_network_acl_rule" "private_inbound" {
      + cidr_block     = "0.0.0.0/0"
      + egress         = false
      + from_port      = 0
      + id             = (known after apply)
      + network_acl_id = (known after apply)
      + protocol       = "-1"
      + rule_action    = "allow"
      + rule_number    = 100
      + to_port        = 0
    }

  # module.vpc.aws_network_acl_rule.private_outbound[0] will be created
  + resource "aws_network_acl_rule" "private_outbound" {
      + cidr_block     = "0.0.0.0/0"
      + egress         = true
      + from_port      = 0
      + id             = (known after apply)
      + network_acl_id = (known after apply)
      + protocol       = "-1"
      + rule_action    = "allow"
      + rule_number    = 100
      + to_port        = 0
    }

  # module.vpc.aws_network_acl_rule.public_inbound[0] will be created
  + resource "aws_network_acl_rule" "public_inbound" {
      + cidr_block     = "0.0.0.0/0"
      + egress         = false
      + from_port      = 0
      + id             = (known after apply)
      + network_acl_id = (known after apply)
      + protocol       = "-1"
      + rule_action    = "allow"
      + rule_number    = 100
      + to_port        = 0
    }

  # module.vpc.aws_network_acl_rule.public_outbound[0] will be created
  + resource "aws_network_acl_rule" "public_outbound" {
      + cidr_block     = "0.0.0.0/0"
      + egress         = true
      + from_port      = 0
      + id             = (known after apply)
      + network_acl_id = (known after apply)
      + protocol       = "-1"
      + rule_action    = "allow"
      + rule_number    = 100
      + to_port        = 0
    }

  # module.vpc.aws_route.private_nat_gateway[0] will be created
  + resource "aws_route" "private_nat_gateway" {
      + destination_cidr_block = "0.0.0.0/0"
      + id                     = (known after apply)
      + instance_id            = (known after apply)
      + instance_owner_id      = (known after apply)
      + nat_gateway_id         = (known after apply)
      + network_interface_id   = (known after apply)
      + origin                 = (known after apply)
      + route_table_id         = (known after apply)
      + state                  = (known after apply)

      + timeouts {
          + create = "5m"
        }
    }

  # module.vpc.aws_route.private_nat_gateway[1] will be created
  + resource "aws_route" "private_nat_gateway" {
      + destination_cidr_block = "0.0.0.0/0"
      + id                     = (known after apply)
      + instance_id            = (known after apply)
      + instance_owner_id      = (known after apply)
      + nat_gateway_id         = (known after apply)
      + network_interface_id   = (known after apply)
      + origin                 = (known after apply)
      + route_table_id         = (known after apply)
      + state                  = (known after apply)

      + timeouts {
          + create = "5m"
        }
    }

  # module.vpc.aws_route.public_internet_gateway[0] will be created
  + resource "aws_route" "public_internet_gateway" {
      + destination_cidr_block = "0.0.0.0/0"
      + gateway_id             = (known after apply)
      + id                     = (known after apply)
      + instance_id            = (known after apply)
      + instance_owner_id      = (known after apply)
      + network_interface_id   = (known after apply)
      + origin                 = (known after apply)
      + route_table_id         = (known after apply)
      + state                  = (known after apply)

      + timeouts {
          + create = "5m"
        }
    }

  # module.vpc.aws_route_table.private[0] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id           = (known after apply)
    }

  # module.vpc.aws_route_table.private[1] will be created
  + resource "aws_route_table" "private" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id           = (known after apply)
    }

  # module.vpc.aws_route_table.public[0] will be created
  + resource "aws_route_table" "public" {
      + arn              = (known after apply)
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-public"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all         = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-public"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id           = (known after apply)
    }

  # module.vpc.aws_route_table_association.private[0] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.vpc.aws_route_table_association.private[1] will be created
  + resource "aws_route_table_association" "private" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.vpc.aws_route_table_association.public[0] will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.vpc.aws_route_table_association.public[1] will be created
  + resource "aws_route_table_association" "public" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # module.vpc.aws_subnet.private[0] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.10.32.0/20"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.vpc.aws_subnet.private[1] will be created
  + resource "aws_subnet" "private" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.10.48.0/20"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-private-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.vpc.aws_subnet.public[0] will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.10.0.0/20"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = true
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-public-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-public-1a"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.vpc.aws_subnet.public[1] will be created
  + resource "aws_subnet" "public" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "us-east-1b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.10.16.0/20"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = true
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-public-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all                                       = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc-public-1b"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.vpc.aws_vpc.this[0] will be created
  + resource "aws_vpc" "this" {
      + arn                                  = (known after apply)
      + assign_generated_ipv6_cidr_block     = false
      + cidr_block                           = "10.10.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_classiclink                   = (known after apply)
      + enable_classiclink_dns_support       = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all                             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
    }

  # module.vpc.aws_vpc_dhcp_options.this[0] will be created
  + resource "aws_vpc_dhcp_options" "this" {
      + arn                  = (known after apply)
      + domain_name          = "domain.com"
      + domain_name_servers  = [
          + "AmazonProvidedDNS",
        ]
      + id                   = (known after apply)
      + netbios_name_servers = []
      + ntp_servers          = []
      + owner_id             = (known after apply)
      + tags                 = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all             = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
    }

  # module.vpc.aws_vpc_dhcp_options_association.this[0] will be created
  + resource "aws_vpc_dhcp_options_association" "this" {
      + dhcp_options_id = (known after apply)
      + id              = (known after apply)
      + vpc_id          = (known after apply)
    }

  # module.vpc.aws_vpc_endpoint.apigw[0] will be created
  + resource "aws_vpc_endpoint" "apigw" {
      + arn                   = (known after apply)
      + cidr_blocks           = (known after apply)
      + dns_entry             = (known after apply)
      + id                    = (known after apply)
      + network_interface_ids = (known after apply)
      + owner_id              = (known after apply)
      + policy                = (known after apply)
      + prefix_list_id        = (known after apply)
      + private_dns_enabled   = true
      + requester_managed     = (known after apply)
      + route_table_ids       = (known after apply)
      + security_group_ids    = (known after apply)
      + service_name          = "com.amazonaws.us-east-1.execute-api"
      + state                 = (known after apply)
      + subnet_ids            = (known after apply)
      + tags                  = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "apigw-retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "apigw-retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_endpoint_type     = "Interface"
      + vpc_id                = (known after apply)
    }

  # module.vpc.aws_vpc_endpoint.s3[0] will be created
  + resource "aws_vpc_endpoint" "s3" {
      + arn                   = (known after apply)
      + cidr_blocks           = (known after apply)
      + dns_entry             = (known after apply)
      + id                    = (known after apply)
      + network_interface_ids = (known after apply)
      + owner_id              = (known after apply)
      + policy                = (known after apply)
      + prefix_list_id        = (known after apply)
      + private_dns_enabled   = false
      + requester_managed     = (known after apply)
      + route_table_ids       = (known after apply)
      + security_group_ids    = (known after apply)
      + service_name          = "com.amazonaws.us-east-1.s3"
      + state                 = (known after apply)
      + subnet_ids            = (known after apply)
      + tags                  = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "s3-retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + tags_all              = {
          + "Environment" = "dev"
          + "Identifier"  = "retargely"
          + "Name"        = "s3-retargely-retargely-vpc"
          + "Terraform"   = "true"
          + "Workspace"   = "default"
        }
      + vpc_endpoint_type     = "Gateway"
      + vpc_id                = (known after apply)
    }

  # module.vpc.aws_vpc_endpoint_route_table_association.private_s3[0] will be created
  + resource "aws_vpc_endpoint_route_table_association" "private_s3" {
      + id              = (known after apply)
      + route_table_id  = (known after apply)
      + vpc_endpoint_id = (known after apply)
    }

  # module.vpc.aws_vpc_endpoint_route_table_association.private_s3[1] will be created
  + resource "aws_vpc_endpoint_route_table_association" "private_s3" {
      + id              = (known after apply)
      + route_table_id  = (known after apply)
      + vpc_endpoint_id = (known after apply)
    }

  # module.vpc.aws_vpc_endpoint_route_table_association.public_s3[0] will be created
  + resource "aws_vpc_endpoint_route_table_association" "public_s3" {
      + id              = (known after apply)
      + route_table_id  = (known after apply)
      + vpc_endpoint_id = (known after apply)
    }

Plan: 61 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.
```
</details>

## Networking

We have created  1 Network(VPC) of 4096 ips.

4 Subnets of 256 ips (two public, two private with Internet access)


```
public-subnets ["10.0.101.0/24", "10.0.102.0/24"]

pruvate-subnets ["10.0.101.0/24", "10.0.102.0/24"]

```
## Observability

We will consider the following metrics
```
* Scalability
* Reliability
* Availability
* Latency
* Fexibility 
```
## Monitoring and Alerting

We will use Cloudwatch to monitor API Gateway and Lambda Metrics

Key metrics for monitoring AWS Lambda
```
1. Function utilization and performance metrics.
2. Invocation metrics.
3. Concurrency metrics.
4. Provisioned concurrency metrics.
```
Key metrics for monitoring AWS Lambda
```
1. 5XX Error
2. 4XX Error
3. Service health status.
```
## CICD Automation

![alt text](/images/cicd.png "CICD")

Using a CI/CD tool (i.e. Github Actions) 
```
1. The CICD will review the Code using Sonarqube.
2. Using the Terraform Github Actions functions will run the terraform fmt/ validate/ plan.
3. Update the Lambda with new version if required.
4. The CICD will publish the terraform plan in the PR
5. After the PR gets merged to master the CICD will run the Terraform Apply
```

## Permissions 

All infrastructure authentication is controlled by IAM Roles. The FAQs state that the users do not required authentication. 

Wew will use the principle of Least Priviledge 
```
1. We will create specific IAM Roles for Lambda to only access the Resource of the S3 bucket
2. S3 Bucket will be retricted and with ACL configured as private
3. Bussiness Logic will be deployed in the private layer
```

## Calculation Report
![alt text](/images/estimate.png "AWS price estimation")

The above was generated using https://calculator.aws/#/.  Is an approximation for heavy usage on the 100 million requests per month. 





