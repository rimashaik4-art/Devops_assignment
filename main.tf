[200~provider "aws" {
  region = var.region
}

# ------------------------
# VPC (default used)
# ------------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# ------------------------
# Security Group
# ------------------------
resource "aws_security_group" "app_sg" {
  name        = "devops-sg"
  description = "Allow API and SSH"

  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ------------------------
# S3 Bucket (Frontend)
# ------------------------
resource "aws_s3_bucket" "frontend" {
  bucket = "devops-frontend-${random_id.rand.hex}"
}

resource "random_id" "rand" {
  byte_length = 4
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = "*"
      Action = ["s3:GetObject"]
      Resource = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# ------------------------
# ElastiCache (Redis)
# ------------------------
resource "aws_elasticache_subnet_group" "redis_subnet" {
  name       = "redis-subnet"
  subnet_ids = data.aws_subnet_ids.default.ids
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "devops-redis"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnet.name
}

# ------------------------
# EC2 (Backend API)
# ------------------------
resource "aws_instance" "api" {
  ami           = "ami-0f58b397bc5c1f2e8" # Amazon Linux 2 (update if needed)
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = element(data.aws_subnet_ids.default.ids, 0)

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              usermod -a -G docker ec2-user

              docker run -d -p 8080:8080 \
              -e REDIS_HOST=redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379 \
              yourdockerhub/api:latest
              EOF

  tags = {
    Name = "devops-api"
  }
}
