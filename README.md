AWS Application Failure Prediction & DevOps Monitoring System

📌 Project Overview

The AWS Application Failure Prediction & DevOps Monitoring System is a cloud-based DevOps project designed to monitor application health, identify early signs of potential failure, and alert the DevOps team before a major application outage occurs.

The project uses AWS, Docker, Kubernetes, Jenkins, Terraform, GitHub, CloudWatch, and SNS to provide infrastructure automation, application deployment, monitoring, and failure-risk detection.

> **Note:** The failure prediction mechanism currently uses threshold-based risk scoring based on application and infrastructure metrics. It is not a machine-learning model.

---

🏗️ Architecture

                         INTERNET
                            |
                            v
                    +---------------+
                    |      ALB      |
                    | Application   |
                    | Load Balancer |
                    +-------+-------+
                            |
                            v
                    PRIVATE SUBNET
                            |
                    +---------------+
                    |   EC2 Server  |
                    |     K3s       |
                    +-------+-------+
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
           +------+      +------+      +------+
           | Pod 1|      | Pod 2|      | Pod 3|
           +------+      +------+      +------+
              |             |             |
              +-------------+-------------+
                            |
                            v
                    PRIVATE DB SUBNET
                            |
                       +----------+
                       |   RDS    |I 
                       | Database |
                       +----------+

Management:
Developer/Admin
      |
      v
AWS Systems Manager
      |
      v
Private EC2

Monitoring:
EC2 / Application
       |
       v
CloudWatch
       |
       v
Failure Detector
       |
       v
SNS
       |
       v
DevOps Team

---

🚀 Technologies Used

AWS Services

- Amazon VPC
- Amazon EC2
- Amazon RDS
- Application Load Balancer (ALB)
- Amazon CloudWatch
- Amazon SNS
- AWS Secrets Manager
- AWS Systems Manager (SSM)
- AWS IAM
- Internet Gateway
- NAT Gateway

DevOps Tools

- Git
- GitHub
- Jenkins
- Docker
- Kubernetes (K3s)
- Terraform
- Python
- Flask

---

🔄 DevOps Workflow

Developer
    |
    v
GitHub
    |
    v
Jenkins
    |
    v
Docker Build
    |
    v
Kubernetes
    |
    v
Application Pods
    |
    v
AWS ALB
    |
    v
Users

Deployment Process

1. Developer pushes application code to GitHub.
2. Jenkins detects the latest source code.
3. Jenkins checks out the repository.
4. Jenkins builds the Docker image.
5. Docker image is imported into the K3s container runtime.
6. Jenkins deploys Kubernetes manifests.
7. Kubernetes runs three application replicas.
8. ALB routes user traffic to the Kubernetes service.
9. Kubernetes health probes continuously check application health.

---

📊 Failure Prediction Workflow

The monitoring component collects infrastructure and application-related metrics from AWS CloudWatch.

The current system checks:

- CPU utilization
- Memory utilization
- Disk utilization
- Application Load Balancer response latency

Each metric contributes to a risk score when it crosses a defined threshold.

Risk Calculation

Condition| Score
CPU > 80%| +25
Memory > 80%| +25
Disk > 80%| +25
ALB latency > 3 seconds| +25

Risk Levels

0 - 25     → LOW
50         → MEDIUM
75 - 100   → HIGH

When the risk level reaches HIGH, an SNS notification is sent to the DevOps team.

---

🔔 Monitoring & Alerting

CloudWatch collects custom EC2 metrics under:

FailurePrediction/Application

Metrics include:

cpu_usage_system
mem_used_percent
disk_used_percent

Application Load Balancer latency is monitored using:

AWS/ApplicationELB
TargetResponseTime

When multiple abnormal conditions are detected, the Python failure detector calculates the overall risk score.

For a HIGH risk condition:

CloudWatch Metrics
       |
       v
Failure Detector
       |
       v
Risk Score
       |
       v
HIGH
       |
       v
Amazon SNS
       |
       v
DevOps Alert

---

🐳 Docker

The application is packaged as a Docker image.

Example:

docker build -t failure-prediction-app:v1 ./application

The image is then imported into the K3s container runtime.

docker save failure-prediction-app:v1 -o failure-prediction-app.tar

sudo k3s ctr images import failure-prediction-app.tar

Docker Hub is not used in this project.

---

☸️ Kubernetes

The application runs on K3s Kubernetes deployed on a private EC2 instance.

Deployment

Replicas: 3
Container Port: 5000
NodePort: 30080

Kubernetes provides:

- Multiple application replicas
- Health checks
- Application restart capability
- Service discovery
- Load distribution between pods

Health Checks

The application exposes:

/health

Kubernetes uses this endpoint for:

- Readiness probe
- Liveness probe

---

🔐 Security

The project follows a private-backend architecture.

- EC2 is deployed in a private subnet.
- RDS is deployed in private database subnets.
- Application traffic is accessed through the ALB.
- AWS Systems Manager is used for EC2 management.
- Database credentials are stored in AWS Secrets Manager.
- IAM roles are used instead of hard-coded AWS credentials.
- Security groups restrict communication between application and database layers.

---

🏗️ Infrastructure as Code

Terraform is used to provision AWS infrastructure.

Terraform manages resources such as:

VPC
├── Public Subnets
├── Private Subnets
├── Database Subnets
├── Internet Gateway
├── NAT Gateway
├── Route Tables
├── Security Groups
├── EC2
├── RDS
├── ALB
└── IAM Resources

Basic Terraform workflow:

terraform init
terraform plan
terraform apply

---

🔧 Jenkins Pipeline

The Jenkins pipeline automates application deployment.

Pipeline stages:

Checkout
   |
   v
Build Docker Image
   |
   v
Load Image into Kubernetes
   |
   v
Deploy Kubernetes
   |
   v
Verify Deployment

The pipeline deploys:

kubernetes/deployment.yml
kubernetes/service.yml

and verifies the running pods and services.

---

🧪 Application Endpoints

Home

/

Returns application status.

Health

/health

Returns:

{
  "status": "healthy"
}

Stress Test

/stress

Generates CPU workload for testing monitoring behavior.

Error Test

/error

Returns an HTTP 500 application error for testing.

---

📁 Project Structure

application-failure-prediction/
│
├── application/
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
│
├── kubernetes/
│   ├── deployment.yml
│   └── service.yml
│
├── monitoring/
│   └── failure_detector.py
│
├── terraform/
│   ├── provider.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── vpc.tf
│   ├── ec2.tf
│   ├── rds.tf
│   ├── alb.tf
│   ├── iam.tf
│   └── outputs.tf
│
├── Jenkinsfile
├── .gitignore
└── README.md

---

🎯 Project Objectives

- Deploy an application using modern DevOps practices.
- Automate AWS infrastructure using Terraform.
- Containerize the application using Docker.
- Deploy and manage application replicas using Kubernetes.
- Automate deployments using Jenkins.
- Monitor infrastructure and application health using CloudWatch.
- Detect early warning conditions using threshold-based risk scoring.
- Notify the DevOps team using Amazon SNS.
- Maintain secure database credentials using AWS Secrets Manager.
- Manage private EC2 instances using AWS Systems Manager.

---

💡 Key DevOps Concepts Demonstrated

- Infrastructure as Code
- CI/CD
- Containerization
- Kubernetes orchestration
- Cloud monitoring
- Alerting
- Failure-risk detection
- IAM-based access control
- Secrets management
- Private cloud architecture
- Load balancing
- Application health checks
- Automated deployment

---

🔮 Future Enhancements

Possible future improvements include:

- Machine-learning-based failure prediction
- Automated incident remediation
- Kubernetes Horizontal Pod Autoscaling
- Centralized application logging
- Advanced dashboards
- Historical failure analysis
- Multi-node Kubernetes architecture
- Automated rollback mechanisms

---

👨‍💻 Author

Vidhena

AWS & DevOps Project

GitHub Repository:

"https://github.com/vidhena/application-failure-prediction"