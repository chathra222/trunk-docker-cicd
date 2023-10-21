data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["sctp-sandbox-vpc-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

variable "environment" {
  type = list(object({
    name  = string
    value = bool
  }))

  // You can also set a default value if you want
  default = [
    {
      name  = "NEW_FEATURE"
      value = false
    },
  ]
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "sctp-my-app-cluster" #Change

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    sctp-my-app = { #task def and service name -> #Change
      cpu    = 512
      memory = 1024

      # Container definition(s)
      container_definitions = {

        sctp-my-app = { #container name
          essential = true
          image     = "255945442255.dkr.ecr.ap-southeast-1.amazonaws.com/sctp-my-app:latest"
          port_mappings = [
            {
              name          = "sctp-my-app" #container name
              containerPort = 5000
              protocol      = "tcp"
            }
          ]
          readonly_root_filesystem = false
          environment              = var.environment
        }
      }
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                         = flatten(data.aws_subnets.public.ids)
      security_group_ids                 = [aws_security_group.allow_sg.id]
    }
  }
}

resource "aws_security_group" "allow_sg" {
  name        = "allow_tls"
  description = "Allow traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_sg"
  }
}
