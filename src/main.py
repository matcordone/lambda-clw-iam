import boto3
import os
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

s3 = boto3.client("s3")

new_bucket = os.environ["NEW_BUCKET_NAME"]
new_key = os.environ.get("NEW_KEY", "renamed_file.txt")

def lambda_handler(event, context):
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key = event["Records"][0]["s3"]["object"]["key"]
    main(bucket, key)
    delete_old_file(bucket, key)
    return {
        "statusCode": 200,
        "body": "File processed successfully"
    }

def main(old_bucket, old_key):
    old_file = s3.get_object(Bucket=old_bucket, Key=old_key)
    contenido = old_file["Body"].read()
    s3.put_object(Bucket=new_bucket, Key=new_key, Body=contenido)
    logger.info("File %s from bucket %s renamed to %s in bucket %s", old_key, old_bucket, new_key, new_bucket)
    
def delete_old_file(old_bucket, old_key):
    s3.delete_object(Bucket=old_bucket, Key=old_key)
    logger.info("File %s deleted from bucket %s", old_key, old_bucket)