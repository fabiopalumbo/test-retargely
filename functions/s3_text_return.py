import boto3
import os
import time

s3 = boto3.client('s3')

def handler(event, context):
    try:
        response = s3.get_object(Bucket=bucket, Key=key)
        s3_content = response['Body'].read().decode('utf-8')
        print("Textdata")
        print(s3_content)

    except Exception as e:
        print(e)

