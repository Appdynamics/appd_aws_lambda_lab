#TODO: Add tracer import

import json
from faker import Faker
import boto3
import uuid
import os
from random import randint

def lambda_function(event, context):
    retval = {}

    if event['path'] == "/resume/random":
        lambda_client = boto3.client('lambda')
        response = lambda_client.invoke(
            FunctionName = context.function_name.replace("lambda-1", "lambda-2"),
            InvocationType = 'RequestResponse'
        )

        responsePayload = response['Payload'].read().decode('utf-8')        

        if responsePayload is None:
            #TODO: Add in error reporting.

            retval = {
                "statusCode" : 404,
                "body" : None
            }
        elif randint(1, 100) == 74:       
            #TODO: Add in error reporting.

            retval = {
                "statusCode" : 500,
                "body" : "Unknown Error"
            }
        else:
            retval = {
                "statusCode" : 200,
                "body" : responsePayload
            }
    else:
        faker = Faker()

        profile = json.dumps(faker.profile(["job", "company", "ssn", "residence", "username", "name", "mail"]))
        key = uuid.uuid4().hex + ".json"

        #TODO: Add in S3 exit call
        try:
            s3_client = boto3.client('s3')
            s3_client.put_object(Body=profile, Bucket=os.environ["CANDIDATE_S3_BUCKET"], Key=key)

            body = {
                "message": "Uploaded successfully.",                    
                "file" : key
            }

            retval = {
                "statusCode": 201,
                "body": json.dumps(body)
            }
        except Exception as e:

            #TODO: Add in S3 exit call error reporting

            body = {
                "message": "Could not upload resume."
            }

            retval = {
                "statusCode": 500,
                "body": json.dumps(body)
            }

       #TODO: End exit call

    return retval
