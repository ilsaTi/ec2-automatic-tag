import os
import boto3
import logging
from botocore.exceptions import ClientError

TAG_KEY = os.environ['TAG_KEY']
ec2= boto3.resource ('ec2')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):

    owner = ''
    try:
        if 'detail' in event:
            if 'userIdentity' in event['detail']:
                
                id_type = event['detail']['userIdentity']['type']
                if id_type == 'AssumedRole':
                    owner = event['detail']['userIdentity']['principalId'].split(':')[1]
                elif id_type == 'IAMUser':
                    owner = event['detail']['userIdentity']['userName']
                elif id_type == 'Root':
                    owner = 'Root'
                else:
                    owner = ''
                    logger.info(f"No user found: {event['detail']['userIdentity']}")
         
        logger.info(event)
        logger.info(f"Owner :  {owner}")
        
        instance_id = [x['instanceId'] for x in event['detail']['responseElements']['instancesSet']['items']]
        updateEc2Stack_Tags(instance_id[0], owner)

    except ClientError as err:
        logger.info(err)


def updateEc2Stack_Tags(instance_id, owner):
    
    instances=[]
    instance = ec2.Instance(instance_id)
    
    find = False
    if instance.tags:
        for tag in instance.tags:
            if tag['Key'] == TAG_KEY:
                find = True
                break;
    
    if not find:
        updateInstanceTag(instance_id, owner)

            
def updateInstanceTag(instance_id, owner):
    response = ec2.create_tags(Resources=[instance_id], Tags=[{'Key':TAG_KEY, 'Value': owner}])  