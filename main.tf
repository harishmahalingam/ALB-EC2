
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "my-alb"
  vpc_id  = "vpc-02d71941e8e649181"
  subnets = ["subnet-03644421210c068be", "subnet-09b83ca88f6d2ab35"]

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    # 
    # ex-https = {
    #   port            = 443
    #   protocol        = "HTTPS"
    #   certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
    #   forward = {
    #     target_group_key = "ex-instance"
    #   }
    # }
  }

  target_groups = {
    ex-instance = {
      name_prefix = "h1"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      target_id   = aws_instance.example.id
    }
  }
}

resource "aws_instance" "example" {
  ami           = "ami-084568db4383264d4" # Replace with your desired AMI ID
  instance_type = "t2.micro"              # Replace with your desired instance type

  vpc_security_group_ids = [aws_security_group.example.id]
  subnet_id              = "subnet-03644421210c068be" # Use the same subnet as your ALB

  user_data = <<-EOF
              #!/bin/bash
              echo "Updating package list"
              apt-get update
              echo "Installing Docker"
              apt-get install -y docker.io
              echo "Starting Docker service"
              systemctl start docker
              echo "Enabling Docker service"
              systemctl enable docker
              echo "Running OpenProject container"
              docker run -it -p 80:80 \
              -e OPENPROJECT_SECRET_KEY_BASE=secret \
              -e OPENPROJECT_HTTPS=false \
              -e OPENPROJECT_DEFAULT__LANGUAGE=en \
              openproject/openproject:15.4.1
              EOF

  tags = {
    Name        = "demo-alb-case01"
    Environment = "Development"
    Project     = "Example"
  }
}

resource "aws_security_group" "example" {
  name        = "example-sg"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = "vpc-02d71941e8e649181"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "example-sg"
    Environment = "Development"
    Project     = "Example"
  }
}

resource "aws_lb_target_group_attachment" "example" {
  target_group_arn = module.alb.target_groups["ex-instance"].arn
  target_id        = aws_instance.example.id
  port             = 80
}
