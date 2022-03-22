import json
import boto3

s3_client = boto3.client("s3")
S3_BUCKET = 'BUCKET'
S3_PREFIX = 'FILE'


def handler(event, context):
    response = s3_client.list_objects_v2(
        Bucket=S3_BUCKET, Prefix=S3_PREFIX, StartAfter=S3_PREFIX,)
    s3_files = response["Contents"]
    for s3_file in s3_files:
        file_content = json.loads(s3_client.get_object(
            Bucket=S3_BUCKET, Key=s3_file["Key"])["Body"].read())
        print(file_content)        

