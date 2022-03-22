{
  "Version": "2012-10-17",
  "Id": "default",
  "Statement": [
    {
      "Sid": "apig-functiongetEndpointPermission-BWDBXMPLXE2F",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "lambda:InvokeFunction",
      "Resource": "${var.lambda_arn}",

    }
  ]
}