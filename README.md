# ☁️ AWS Java Platform

**Three-Tier Java Application · AWS · Terraform · Session Manager · CI/CD**

Infrastructure as Code project focused on deploying a Java web application on AWS using a three-tier architecture. The project explores infrastructure provisioning, application packaging, deployment automation and cloud infrastructure management through Terraform and GitHub Actions.

> 🎯 **Project goal:** Build a reproducible, maintainable and documented cloud environment following Infrastructure as Code and CI/CD practices.

---

## 🏗️ Architecture

The platform is designed around a three-tier architecture, separating the application into distinct logical layers to improve maintainability, security and scalability.

| Layer               | Purpose                                                 |
| ------------------- | ------------------------------------------------------- |
| 🌐 **Presentation** | Handles incoming incoming HTTP/HTTPS requests and web traffic.   |
| ⚙️ **Application**  | Runs the Java application and processes business logic. |
| 🗄️ **Data**         | Provides persistent data storage for the application.   |

**Architecture diagram:**

```text
Internet (0.0.0.0/0)
       │
       ▼  :80
   ┌─────────┐
   │   ALB   │  sg-alb
   └────┬────┘
        ▼  :80
   ┌─────────┐
   │  Nginx  │  sg-nginx
   └────┬────┘
        ▼  :8080
   ┌─────────┐     :3306     ┌─────────┐
   │  Tomcat │ ────────────▶ │  RDS    │
   │  (EC2)  │               │ (MySQL) │
   └─────────┘               └─────────┘
   public subnet             private subnet

   🔐 Access: AWS Session Manager (no SSH, no open ports)
```

_VPC: `10.0.0.0/16` · Region: `eu-west-1` · All resources provisioned with Terraform._

---

## 🛠️ Technology Stack

| Technology            | Purpose                                           |
| --------------------- | ------------------------------------------------- |
| ☁️ AWS                | Cloud infrastructure                              |
| 🏗️ Terraform          | Infrastructure as Code (IaC)                      |
| ☕ Java 11+           | Application development and runtime compatibility |
| 📦 Maven 3.9+         | Dependency management and application packaging   |
| 🔄 GitHub Actions     | CI/CD workflow automation                         |
| 🔑 AWS CLI            | AWS resource and deployment management            |
| 🖥️ Session Manager    | Secure shell access without SSH ports             |
| 🐳 Amazon Linux 2023  | EC2 operating system (patched, supported)         |

---

## 📁 Project Structure

```text
aws-java-platform/
├── app/                    # Java web application (WAR)
├── terraform/              # Infrastructure as Code
├── .github/
│   └── workflows/          # CI/CD pipeline definitions
└── docs/                   # Architecture and technical documentation
```

---

## 🚀 Getting Started

### Prerequisites

Before working with the project, make sure you have the following tools installed:

- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [Java / Eclipse Temurin](https://adoptium.net/) 11+
- [Apache Maven](https://maven.apache.org/) 3.9+

You will also need an AWS account with the appropriate IAM permissions for the resources defined in the Terraform configuration.

### Deployment

Infrastructure is provisioned with Terraform and the application is deployed and running.

1. ✅ AWS credential configuration and permission validation.
2. ✅ Terraform initialization and configuration validation.
3. ✅ Infrastructure planning and provisioning (VPC, subnets, security groups, RDS, EC2).
4. ✅ Java application packaging and deployment on Tomcat.
5. ✅ Security hardening (Session Manager, Cost Explorer enabled).
6. ✅ Migration from Amazon Linux 2 to Amazon Linux 2023 (EOL June 2026).
7. ✅ Access via Session Manager (SSH removed).
8. 🟡 RDS upgrade to MySQL 8.4 LTS.
9. 🟡 CI/CD pipeline automation with GitHub Actions.
10. ⚪ Infrastructure cleanup to prevent unnecessary AWS charges.

---

## 🖥️ Server Access

Servers are accessed via **AWS Session Manager** — no SSH keys, no open ports, no IP whitelisting.

### Connect via AWS Console

1. Navigate to **EC2 → Instances → Select instance**
2. Click **Connect → Session Manager tab**
3. Click **Connect**

### Connect via AWS CLI

```bash
aws ssm start-session --target <instance-id> --region eu-west-1
```

### Benefits over traditional SSH

| Feature               | SSH                  | Session Manager      |
| --------------------- | -------------------- | -------------------- |
| Open ports required   | Port 22              | None                 |
| Key pair management   | Required             | Not needed           |
| IP whitelisting       | Required             | Not needed           |
| Access from browser   | No                   | Yes                  |
| Audit trail           | SSH logs only        | CloudTrail + CW      |
| Cost                  | $0                   | $0                   |
| Secrets in code       | IPs possible         | None                 |

---

## 🔐 Security Considerations

Security is an important part of the infrastructure design.

- 🔑 Use IAM roles and least-privilege permissions wherever possible.
- 🔒 Never commit AWS credentials, private keys, passwords or sensitive `.tfvars` files.
- 🗝️ Store deployment secrets in GitHub Actions Secrets or an appropriate secrets management service.
- 🌐 Restrict inbound traffic through security groups and expose only the ports required by the application.
- 🖥️ **Server access via Session Manager only** — no SSH ports open, no key pairs, no IPs in code.
- 🛡️ IAM Role with `AmazonSSMManagedInstanceCore` policy for EC2 instances.
- 🧹 Review provisioned resources and remove unused infrastructure to avoid unnecessary costs.
- 📊 Cost Explorer enabled for cost monitoring and anomaly detection.

---

## 💰 Cost Management

AWS resource costs depend on the services, instance types, storage and network configuration selected for deployment.

**Estimated monthly cost (resources stopped):**

| Resource     | Spec              | Est. Cost     |
| ------------ | ----------------- | ------------- |
| EC2          | t3.micro (stopped)| ~$0.80 (EBS)  |
| RDS          | db.t3.micro (stopped) | ~$2.00 (storage) |
| VPC/Subnets  | —                 | Free          |
| Session Manager | —               | Free          |
| **Total**    |                   | **~$2.80/mo** |

_Free Tier eligible: 750 hrs/month of t3.micro and db.t3.micro._

The deployment guide includes infrastructure cleanup instructions to avoid leaving billable resources running.

---

## 🧪 Project Status

**Current focus:** RDS upgrade and CI/CD automation.

| Component                      | Status                |
| ------------------------------ | --------------------- |
| Project structure              | ✅ Completed          |
| Terraform infrastructure       | ✅ Completed          |
| Java application deployment    | ✅ Completed          |
| Session Manager access         | ✅ Completed          |
| Amazon Linux 2023 migration    | ✅ Completed          |
| Security hardening             | ✅ Completed          |
| Cost Explorer                  | ✅ Completed          |
| RDS upgrade to MySQL 8.4       | 🟡 In progress        |
| CI/CD automation               | ⚪ Pending            |
| Architecture documentation     | 🟡 In progress        |
| Cost estimation                | ✅ Completed          |

_Statuses are updated as each component is implemented and verified._

---

## 📚 Learning Objectives

This project is intended to demonstrate practical experience with:

- Infrastructure as Code and repeatable provisioning.
- AWS infrastructure fundamentals and resource management.
- Java application packaging and deployment.
- CI/CD workflow design with GitHub Actions.
- Cloud security, access control and cost awareness.
- Session Manager and passwordless server access.
- Technical documentation and infrastructure lifecycle management.

---

## 📄 License

Educational and portfolio project. See the repository license file if one is added.

---

_Built as a hands-on cloud infrastructure project._
