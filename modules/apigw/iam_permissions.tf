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

#Define a policy which will allow APIGW to access your s3
data "aws_iam_policy_document" "api_gw_access_s3_assume_policy" {
  statement = [
      {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectAcl"
      ]
      resources = [
        "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:{var.bucket}",
        "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:{var.bucket}/*",
      ]
      },
      {
      effect = "Allow"
      actions = [
        "s3:ListAllMyBuckets"
      ]
      resources = "*"
      },
      {
      effect = "Allow"
      actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ]
      resources = [
        "arn:aws:s3:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:{var.bucket}"
      ]
      }         
  ]
}

#creates a new iam role
resource "aws_iam_role" "api_gw_role" {
  name               = "${var.identifier}-api_gw_role-${random_string.this.id}"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume_role.json
}

#attach s3 access policy
resource "aws_iam_role_policy" "api_gw_access_s3_policy" {
  name   = "${var.identifier}-api_s4-${random_string.this.id}"
  role   = aws_iam_role.api_gw_role.name
  policy = data.aws_iam_policy_document.api_gw_access_s3_assume_policy.json
}
