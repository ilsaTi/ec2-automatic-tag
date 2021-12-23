# Automatic Tagging Of AWS EC2 using Terraform

One of the best practices is to create tags to categorize resources by owner. This can be archived multiple ways. AWS Service Catalog is one of the best options to enforce tagging. Here, we are using IaC to deploy an event-based solution that will automatically tag the owner to EC2 resources after their creation. We will use Terraform to archieve this.

## Use-case

Here is a summary of the solution:

1. a user launches an EC2 instance
2. a **RunInstances** event is detected in CloudTrail
3. upon event detection, the lambda function is triggered
4. the lambda function identifies the owner and tag the EC2 instance accordingly if owner tag is missing
    
![Alt text](diagram.PNG?raw=true)

## Solution

### Pre-requisites
1. Have CloudTrail created and CloudWatch able to monitor the trail 
2. Terraform (refer to the installation steps [here](https://learn.hashicorp.com/tutorials/terraform/install-cli))
3. AWS CLI (refer to the installation steps [here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.htm))

### Infrastructure

#### Lambda function

Here is how to create the Lambda function. 

```python
resource "aws_lambda_function" "function" {
  filename      = "code/code.zip"
  function_name = "tagEc2"
  role          = aws_iam_role.lambda_assumeRole_policy.arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  environment {
    variables = {
        TAG_KEY = var.tag_key
    }
  }
  timeout = 600
}

# role lambda
resource "aws_iam_role" "lambda_assumeRole_policy" {
  name = "tagEc2-Role"
  assume_role_policy = data.local_file.lambda_assumeRole_policy.content
}

# iam policy
resource "aws_iam_role_policy" "pol" {
  name = "lambda_tagEc2_policy"
  role = aws_iam_role.lambda_assumeRole_policy.id
  policy = data.local_file.lambda_policy.content
}
```
Note that the IAM policies contents are stored in a local file for more convenience.

#### Event rule

The event rule and target are as follow:

```python
resource "aws_cloudwatch_event_rule" "event_rule" {
  name        = "launch-auto-tags"
  description = ""
  event_pattern = data.local_file.event_pattern.content
}

resource "aws_cloudwatch_event_target" "target" {
  target_id = "lambda"
  rule      = aws_cloudwatch_event_rule.event_rule.name
  arn       = aws_lambda_function.function.arn
}
```
The content of event pattern is also stored in a local file. 

### Deploy

To deploy, the commands below must be run with the appropriate parameters:

```bash
terraform init
terraform validate
terraform plan
terraform apply -var account_id="ACCOUNT_ID" -var tag_key="TAG_KEY"
```

- *ACCOUNT_ID*: the account ID (must be updated in *lambda_policy.json*)
- *TAG_KEY*: the tag key (i.e: Principal, Owner, ... ), default value is *owner*


## Result

The following resources are created:

1. The lambda function

2. The EventBridge rule


## Improvements

One could imbricate the policy from *lambda_policy.json*.

```python
# iam policy
resource "aws_iam_role_policy" "pol" {
  name = "lambda_tagEc2_policy"
  role = aws_iam_role.lambda_assumeRole_policy.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:${var.aws_region}:${var.account_id}:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:${var.aws_region}:${var.account_id}:*:*:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
POLICY
}
```

## Documentation

- [Automatically tagging resources on AWS upon Initialization](https://vticloud.io/en/tu-dong-gan-the-cac-tai-nguyen-tren-aws-khi-khoi-tao/)
