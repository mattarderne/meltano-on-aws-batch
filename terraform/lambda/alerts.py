#!/usr/bin/env python

import boto3
import os
import random 
import string
import requests

alert_map = {
    "emoji": {
        "up": ":white_check_mark:",
        "down": ":fire:"
    },
    "text": {
        "up": "Success",
        "down": "Fail"
    },
    "color": {
        "up": "#32a852",
        "down": "#ad1721"
    }
}

def alert_to_slack(status, message):
    '''
    Sends a slack alert based on the Slack webhook set in the Terraform setup
    '''

    url = os.environ['ALERT_WEBHOOK']
    
    data = {
        "text": "Meltano ELT",
        "username": "Notifications",
        "attachments": [
        {
            "text": "{emoji} *{state}*\n {message}".format(
                emoji=alert_map["emoji"][status],
                state=alert_map["text"][status],
                message=message
            ),
            "color": alert_map["color"][status],
            "attachment_type": "default",
        }]
    }
    r = requests.post(url, json=data)
    return r.status_code

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
    alert_toggle = os.environ['ALERT_TOGGLE']

    # Create unique name for the job (this does not need to be unique)
    job_name = job_def + '-' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=4))

    # Set up a batch client 
    session = boto3.session.Session()
    client = session.client('batch')

    try:
        # Submit the job
        job1 = client.submit_job(
            jobName=job_name,
            jobQueue=job_queue,
            jobDefinition=job_def
        )

        if alert_toggle == 'true':
            alert_to_slack('up', f'Started job: {job_name}')
    except:
        if alert_toggle == 'true':
            alert_to_slack('down', f'Start job failed: {job_name}')