from discord import Webhook, RequestsWebhookAdapter
# Use this code snippet in your app.
# If you need more information about configurations or implementing the sample code, visit the AWS docs:   
# https://aws.amazon.com/developers/getting-started/python/

import boto3
import base64
from botocore.exceptions import ClientError
import json
import copy

def get_secret():
    secret_name = "dev/DiscordWebhook1"
    region_name = "us-east-1"

    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name="secretsmanager",
        region_name=region_name
    )

    # In this sample we only handle the specific exceptions for the "GetSecretValue" API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "DecryptionFailureException":
            # Secrets Manager can"t decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response["Error"]["Code"] == "InternalServiceErrorException":
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response["Error"]["Code"] == "InvalidParameterException":
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response["Error"]["Code"] == "InvalidRequestException":
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response["Error"]["Code"] == "ResourceNotFoundException":
            # We can"t find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
    else:
        # Decrypts secret using the associated KMS key.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if "SecretString" in get_secret_value_response:
            secret = get_secret_value_response["SecretString"]
            return secret
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response["SecretBinary"])
            return decoded_binary_secret

def send_message(webhook, message):
    if len(message) > 0:
        webhook.send(message)

def generate_dashboard_json(instance_id, region_id="us-east-1"):
    dashboard_dict = {
      "widgets": [
        {
          "type": "metric",
          "x": 0,
          "y": 0,
          "width": 12,
          "height": 6,
          "properties": {
            "metrics": [
              [
                "AWS/EC2",
                "NetworkIn",
                "InstanceId",
                instance_id
              ],
              [
                "AWS/EC2",
                "NetworkOut",
                "InstanceId",
                instance_id
              ]
            ],
            "period": 300,
            "stat": "Average",
            "region": region_id,
            "title": "NetworkIn/Out"
          }
        },
        {
          "type": "metric",
          "x": 12,
          "y": 0,
          "width": 12,
          "height": 6,
          "properties": {
            "metrics": [
              [
                "AWS/EC2",
                "NetworkPacketsIn",
                "InstanceId",
                instance_id
              ],
              [
                "AWS/EC2",
                "NetworkPacketsOut",
                "InstanceId",
                instance_id
              ]
            ],
            "period": 300,
            "stat": "Average",
            "region": region_id,
            "title": "NetworkPacketsIn/Out"
          }
        },
        {
          "type": "metric",
          "x": 0,
          "y": 6,
          "width": 12,
          "height": 6,
          "properties": {
            "metrics": [
              [
                "AWS/EC2",
                "CPUUtilization",
                "InstanceId",
                instance_id
              ]
            ],
            "period": 300,
            "stat": "Average",
            "region": region_id,
            "title": "CPUUtilization"
          }
        }
      ]
    }
    return json.dumps(dashboard_dict)

def handler(event, context):
    discord_webhook = json.loads(get_secret())["discord_webhook_1"]

    webhook = Webhook.from_url(discord_webhook, adapter=RequestsWebhookAdapter())
    try:
        # Init boto3 clients
        ec2_client = boto3.client("ec2")
        asg_client = boto3.client("autoscaling")
        cw_client = boto3.client("cloudwatch")

        # Get all the instances in the given auto scaling group name
        sns_message = json.loads(event["Records"][0]["Sns"]["Message"])
        asg_name = sns_message["AutoScalingGroupName"]
        message = f"ASG:  {asg_name}\n"
        send_message(webhook, message)
        nat_asg = asg_client.describe_auto_scaling_groups(
            AutoScalingGroupNames=[asg_name]
        )
        nat_asg_query_result = nat_asg["AutoScalingGroups"][0]["Instances"]
        
        # Get all the instance IDs in the auto scaling group where source and destination check is true
        nat_asg_ec2s_descriptions = ec2_client.describe_instances(
            InstanceIds=[ec2["InstanceId"] for ec2 in nat_asg_query_result if "InstanceId" in ec2]
        )
        nat_asg_ec2s = nat_asg_ec2s_descriptions["Reservations"][0]["Instances"]
        ec2s_to_disable_source = [ec2 for ec2 in nat_asg_ec2s if ec2["NetworkInterfaces"][0]["SourceDestCheck"] == True]

        # Get non-main route tables
        route_tables = ec2_client.describe_route_tables()["RouteTables"]
        _ = []
        for i, rt in enumerate(route_tables):
            for association in rt["Associations"]:
                if association["Main"] == True:
                    _.append(i)
        non_main_rt = [i for j, i in enumerate(route_tables) if j not in _]

        # Get non-main route tables that need to be associated
        _ = []
        message = ""
        for j, nmrt in enumerate(non_main_rt):
            for route in nmrt["Routes"]:
                # Don't include if it already has active for 0.0.0.0/0, regardless if its a NAT or Internet gateway
                if route["DestinationCidrBlock"] == "0.0.0.0/0" and route["State"] == "active":
                    _.append(j)
                # If there is blackhole for 0.0.0.0/0, delete the route
                elif route["DestinationCidrBlock"] == "0.0.0.0/0" and  route["State"] == "blackhole":
                    ec2_client.delete_route(DestinationCidrBlock = "0.0.0.0/0", RouteTableId=nmrt["RouteTableId"])
                    update_message = f"Delete route 0.0.0.0/0 in {nmrt['RouteTableId']}\n"
                    if route['NetworkInterfaceId']:
                      cw_client.delete_dashboards(DashboardName=[f"NAT-{route['NetworkInterfaceId']}"])
                      update_message += f"Deleted dashboard NAT-{route['NetworkInterfaceId']}"
                    message += update_message
        route_tables_to_associate = [i for j, i in enumerate(non_main_rt) if j not in _]
        send_message(webhook, message)

        # Disable any source and destination check for instances that still is true
        # Then add dashboard
        message = ""
        for ec2 in ec2s_to_disable_source:
            ec2_client.modify_instance_attribute(InstanceId=ec2["InstanceId"], SourceDestCheck={"Value": False})
            update_message = f"Disabled source destination check for instance {ec2['InstanceId']} with status {ec2['State']['Name']}\n"
            message += update_message
            # Associate the ENI of disabled source/destination check to private route tables
            for rt in route_tables_to_associate:
                ec2_client.create_route(
                    DestinationCidrBlock ="0.0.0.0/0",
                    NetworkInterfaceId=ec2["NetworkInterfaces"][0]["NetworkInterfaceId"],
                    RouteTableId = rt["RouteTableId"]
                    )
                update_message = f"Attach ENI to {rt['RouteTableId']}\n"
                cw_client.put_dashboard(DashboardName=f"NAT-{ec2['NetworkInterfaces'][0]['NetworkInterfaceId']}",
                    DashboardBody=generate_dashboard_json(ec2['InstanceId'])
                  )
                update_message += f"Added dashboard NAT-{ec2['NetworkInterfaces'][0]['NetworkInterfaceId']}"
                message += update_message
        send_message(webhook, message)
    except Exception as e:
        # Send error to discord, if any
        webhook.send("ERROR : "+str(e))