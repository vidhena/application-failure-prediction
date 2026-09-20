import boto3
from datetime import datetime, timedelta

cloudwatch = boto3.client(
    "cloudwatch",
    region_name="ap-southeast-1"
)

sns = boto3.client(
    "sns",
    region_name="ap-southeast-1"
)

NAMESPACE = "FailurePrediction/Application"

SNS_TOPIC_ARN = (
    "arn:aws:sns:ap-southeast-1:728735520119:"
    "failure-prediction-alerts"
)

HOST = "ip-10-0-11-198.ap-southeast-1.compute.internal"

ALB_NAME = "app/failure-prediction-alb/c53eaa51151693a1"


def get_metric(metric_name, dimensions):
    response = cloudwatch.get_metric_statistics(
        Namespace=NAMESPACE,
        MetricName=metric_name,
        Dimensions=dimensions,
        StartTime=datetime.utcnow() - timedelta(minutes=1),
        EndTime=datetime.utcnow(),
        Period=60,
        Statistics=["Average"]
    )

    datapoints = response.get("Datapoints", [])

    if not datapoints:
        return 0

    return datapoints[-1]["Average"]


def get_alb_latency():
    response = cloudwatch.get_metric_statistics(
        Namespace="AWS/ApplicationELB",
        MetricName="TargetResponseTime",
        Dimensions=[
            {
                "Name": "LoadBalancer",
                "Value": ALB_NAME
            }
        ],
        StartTime=datetime.utcnow() - timedelta(minutes=1),
        EndTime=datetime.utcnow(),
        Period=60,
        Statistics=["Average"]
    )

    datapoints = response.get("Datapoints", [])

    if not datapoints:
        return 0

    return datapoints[-1]["Average"]


def calculate_risk():

    # CPU
    cpu = get_metric(
        "cpu_usage_system",
        [
            {
                "Name": "host",
                "Value": HOST
            },
            {
                "Name": "cpu",
                "Value": "cpu-total"
            }
        ]
    )

    # Memory
    memory = get_metric(
        "mem_used_percent",
        [
            {
                "Name": "host",
                "Value": HOST
            }
        ]
    )

    # Disk
    disk = get_metric(
        "disk_used_percent",
        [
            {
                "Name": "path",
                "Value": "/"
            }
        ]
    )

    # ALB latency
    latency = get_alb_latency()

    # Risk calculation
    score = 0

    if cpu > 80:
        score += 25

    if memory > 80:
        score += 25

    if disk > 80:
        score += 25

    if latency > 3:
        score += 25

    # Risk level
    if score >= 75:
        risk = "HIGH"
    elif score >= 50:
        risk = "MEDIUM"
    else:
        risk = "LOW"

    print("--------------------------------")
    print("Application Failure Prediction")
    print("--------------------------------")

    print(f"CPU Usage: {cpu:.2f}%")
    print(f"Memory Usage: {memory:.2f}%")
    print(f"Disk Usage: {disk:.2f}%")
    print(f"ALB Latency: {latency:.3f} seconds")

    print(f"Risk Score: {score}")
    print(f"Risk Level: {risk}")

    # Send SNS alert for HIGH risk
    if risk == "HIGH":

        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="HIGH RISK - Application Failure Prediction",
            Message=f"""
Application Failure Prediction Alert

Risk Level: HIGH
Risk Score: {score}

CPU Usage: {cpu:.2f}%
Memory Usage: {memory:.2f}%
Disk Usage: {disk:.2f}%
ALB Latency: {latency:.3f} seconds

Immediate DevOps investigation is recommended.
"""
        )

        print("SNS alert sent!")


if __name__ == "__main__":
    calculate_risk()