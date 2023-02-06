provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "vpc-prod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "Prod"
  }
}
#
resource "aws_internet_gateway" "Altschool_internet_gt" {
  vpc_id = aws_vpc.vpc-prod.id
}
resource "aws_route_table" "Altsch-route-table-public" {
  vpc_id = aws_vpc.vpc-prod.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Altschool_internet_gt.id
  }
  tags = {
    Name = "Altsch-route-table-public"
  }
}

resource "aws_subnet" "Altsch-public-subnet1" {
  vpc_id                  = aws_vpc.vpc-prod.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "Altsch-public-subnet1"
  }
}
resource "aws_subnet" "Altsch-public-subnet2" {
  vpc_id                  = aws_vpc.vpc-prod.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "Altsch-public-subnet2"
  }
}

resource "aws_route_table_association" "Altsch-public-subnet1-association" {
  subnet_id      = aws_subnet.Altsch-public-subnet1.id
  route_table_id = aws_route_table.Altsch-route-table-public.id
}

resource "aws_route_table_association" "Altsch-public-subnet2-association" {
  subnet_id      = aws_subnet.Altsch-public-subnet2.id
  route_table_id = aws_route_table.Altsch-route-table-public.id
}

resource "aws_network_acl" "Altsch-network_acl" {
  vpc_id = aws_vpc.vpc-prod.id
  subnet_ids = [aws_subnet.Altsch-public-subnet1.id, aws_subnet.Altsch-public-subnet2.id]

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port = 0
}

}

resource "aws_security_group" "Altschool-load_balancer_sg" {
  name        = "Altschool-load-balancer-sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.vpc-prod.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "Altschool-security-grp-rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.vpc-prod.id
 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Altschool-load_balancer_sg.id]
  }
 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.Altschool-load_balancer_sg.id]
  }
  ingress {
    description = "SSH"
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
    Name = "Altschool-security-grp-rule"
  }
}
resource "aws_instance" "Altschool1" {
  ami             = "ami-00874d747dde814fa"
  instance_type   = "t2.micro"
  key_name        = "main-key"
  security_groups = [aws_security_group.Altschool-security-grp-rule.id]
  subnet_id       = aws_subnet.Altsch-public-subnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Altschool-1"
    source = "terraform"
  }
}

 resource "aws_instance" "Altschool2" {
  ami             = "ami-00874d747dde814fa"
  instance_type   = "t2.micro"
  key_name        = "main-key"
  security_groups = [aws_security_group.Altschool-security-grp-rule.id]
  subnet_id       = aws_subnet.Altsch-public-subnet2.id
  availability_zone = "us-east-1b"
  tags = {
    Name   = "Altschool-2"
    source = "terraform"
  }
}

resource "aws_instance" "Altschool3" {
  ami             = "ami-00874d747dde814fa"
  instance_type   = "t2.micro"
  key_name        = "main-key"
  security_groups = [aws_security_group.Altschool-security-grp-rule.id]
  subnet_id       = aws_subnet.Altsch-public-subnet1.id
  availability_zone = "us-east-1a"
  tags = {
    Name   = "Altschool-3"
    source = "terraform"
  }
}
resource "local_file" "Ip_address" {
  filename = "/home/sulaiman/terraform/assignment_project//host-inventory"
  content  = <<EOT
${aws_instance.Altschool1.public_ip}
${aws_instance.Altschool2.public_ip}
${aws_instance.Altschool3.public_ip}
  EOT
}

resource "aws_lb" "Altschool-load-balancer" {
  name               = "Altschool-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Altschool-load_balancer_sg.id]
  subnets            = [aws_subnet.Altsch-public-subnet1.id, aws_subnet.Altsch-public-subnet2.id]
  enable_deletion_protection = false
  depends_on                 = [aws_instance.Altschool1, aws_instance.Altschool2, aws_instance.Altschool3]
}
resource "aws_lb_target_group" "Altschool-target-group" {
  name     = "Altschool-target-group"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc-prod.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "Altschool-listener" {
  load_balancer_arn = aws_lb.Altschool-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  }
}

resource "aws_lb_listener_rule" "Altschool-listener-rule" {
  listener_arn = aws_lb_listener.Altschool-listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_alb_target_group_attachment" "Altschool-target-group-attachment1" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool1.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment2" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool2.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "Altschool-target-group-attachment3" {
  target_group_arn = aws_lb_target_group.Altschool-target-group.arn
  target_id        = aws_instance.Altschool3.id
  port             = 80 
  
  }