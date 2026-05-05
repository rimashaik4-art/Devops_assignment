# Devops_assignment


Frontend: React (hosted on S3 static website)
Backend: Rust API (Dockerized, running on EC2)
Database: Redis (AWS ElastiCache)


**Technologies Used**
AWS (S3, EC2, ElastiCache)
Terraform (Infrastructure as Code)
Docker (Containerization)
React (Frontend)
Rust (Backend API)
Redis (Database)


**Provision infrastructure using Terraform:**

cd terraform
terraform init
terraform apply
Resources Created:
S3 bucket (frontend hosting with static website)
EC2 instance (backend API)
ElastiCache Redis cluster
Security groups


**User accesses frontend via S3 website URL**
S3 serves static React files
React app runs in browser
Browser sends API requests to EC2 backend
Backend interacts with Redis
Response is returned to frontend
