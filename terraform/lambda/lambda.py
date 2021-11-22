#!/usr/bin/env python

import boto3
import os
import random 
import string

def lambda_handler(event,context):
    '''
    This lambda handler submits a job to a AWS Batch queue.
    JobQueue, and JobDefinition environment variables must be set. 
    These environment variables are intended to be set to the Name, not the Arn. 
    Can be reused by any of the Jobs
    '''

    # Grab data from environment
    job_queue = os.environ['JOB_QUEUE']
    job_def = os.environ['JOB_DEFINITION']

    # Create unique name for the job (this does not need to be unique)
    job_name = job_def + '-' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))

    # Set up a batch client 
    session = boto3.session.Session()
    client = session.client('batch')


    # Submit the job
    job = client.submit_job(
        jobName=job_name,
        jobQueue=job_queue,
        jobDefinition=job_def
    )
    return job