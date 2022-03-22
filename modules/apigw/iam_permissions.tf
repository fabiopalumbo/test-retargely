#Define a policy which will allow APIGW to Assume an IAM Role
data "aws_iam_policy_document" "apigw_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

# Define a policy which will allow APIGW to access your s3
data "aws_iam_policy_document" "api_gw_lambda_invoke_policy" {
  statement {
      effect = "Allow"
      actions = [
        "lambda:InvokeFunction"
      ]
      resources = [
        "var.lambda_arn",
      ]
  }
}

#creates a new iam role
resource "aws_iam_role" "api_gw_role" {
  name               = "${var.identifier}-api_gw_role-${random_string.this.id}"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume_role.json
}

#attach s3 access policy
resource "aws_iam_role_policy" "api_gw_access_s3_policy" {
  name   = "${var.identifier}-api_invoke-${random_string.this.id}"
  role   = aws_iam_role.api_gw_role.name
  policy = data.aws_iam_policy_document.api_gw_lambda_invoke_policy.json
}
