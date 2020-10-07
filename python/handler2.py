#TODO: Add tracer import

import json
from random import randint
import boto3
import os

def lambda_function(event, context):

    s3_client = boto3.client('s3')

    #TODO: Add in S3 exit call
    objs = s3_client.list_objects_v2(Bucket = os.environ["CANDIDATE_S3_BUCKET"])['Contents']
    idx = randint(0, len(objs) - 1)

    obj_key = objs[idx]['Key']    
    obj = s3_client.get_object(Bucket = os.environ["CANDIDATE_S3_BUCKET"], Key = obj_key)
    obj_contents = json.loads(obj['Body'].read().decode('utf-8'))

    response = {
        "file" : obj_key,
        "contents" : obj_contents
    }

    if randint(1, 100) == 74:
        response = None

    return response
