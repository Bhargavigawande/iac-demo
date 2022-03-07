terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
#Create VPC
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}
#Create Internet Gateway
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myVPC Internet Gateway"
  }
}
#Create Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags={
    Name = "Public Subnet 1"
  }
}
#Create Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags={
    Name = "Private Subnet 1"
  }
}
#Create Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags={
    Name = "Public Subnet 2"
  }
}
#Create Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags={
    Name = "Private Subnet 2"
  }
}
#Create public route table with association
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    "Name" = "Public Route Table"
  }


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.InternetGateway.id
  }

}
resource "aws_route_table_association" "PublicRouteTableAssociation1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table_association" "PublicRouteTableAssociation2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.PublicRouteTable.id
}
#Create Private Route Table Association
resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.myVPC.id
  tags = {
    "Name" = "Private Route Table"
  }
}

resource "aws_route_table_association" "PrivateRouteTableAssociation1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

resource "aws_route_table_association" "PrivateRouteTableAssociation2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}
#Part -2
#Create Security Group
resource "aws_security_group" "InstanceSecurityGroup" {
  name        = "instances security"
  description = "for instances"
  vpc_id      =  aws_vpc.myVPC.id


  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  } 
  
  tags = {
    Name = "instances sg"
  }
}
#Create Launch Configuration
resource "aws_launch_configuration" "myLaunchConfig" {
  name_prefix   = "LaunchConfiguration"
  image_id      = "ami-0c293f3f676ec4f90"
  instance_type = "t2.micro"
  enable_monitoring = true
  security_groups = [aws_security_group.InstanceSecurityGroup.id]
  associate_public_ip_address = true
  user_data= <<EOF
          #!/bin/bash
          # Use this for your user data (script from top to bottom)
          #install httpd (linux 2 version)
          yum update -y
          yum install -y httpd
          systemctl start httpd
          systemctl enable httpd
          echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
  EOF        
}
#Create an Autoscaling group
resource "aws_autoscaling_group" "myASG" {
  name                      = "AutoscalingGroup"
  max_size                  = 4
  min_size                  = 2
  health_check_grace_period = 300
  max_instance_lifetime = 2592000
  health_check_type         = "ELB"
  launch_configuration      = aws_launch_configuration.myLaunchConfig.name
  vpc_zone_identifier       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns = [aws_lb_target_group.myTargetGroup.id]
}
#Create Target Group
resource "aws_lb_target_group" "myTargetGroup" {
  
  name     = "TargetGroup"
  port     = 80
  target_type = "instance"
  protocol = "HTTP"
  vpc_id   = aws_vpc.myVPC.id

   health_check {
    path = "/"
    port = 80
    protocol = "HTTP"
    matcher=200
    
  }
}
#Create Load Balancer
resource "aws_lb" "myLoadBalancer" {
  name               = "LoadBalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.InstanceSecurityGroup.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  

  tags = {
    Name = "myLoadBalancer"
  }

}
#Create Load Balancer Listener
resource "aws_lb_listener" "myLoadBalancerListener" {
  load_balancer_arn = aws_lb.myLoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myTargetGroup.arn
  }
}
resource "aws_autoscaling_attachment" "my_asg_tg_attachment" {
  autoscaling_group_name = "${aws_autoscaling_group.myASG.id}"
  alb_target_group_arn   = "${aws_lb_target_group.myTargetGroup.arn}"
}
#Create Traget Tracking Policy
resource "aws_autoscaling_policy" "myCPUPolicy" {
name = "target-tracking-policy"
policy_type = "TargetTrackingScaling"
autoscaling_group_name = "${aws_autoscaling_group.myASG.name}"
estimated_instance_warmup = 200

target_tracking_configuration {
predefined_metric_specification {
predefined_metric_type = "ASGAverageCPUUtilization"
}

    target_value = "30"

}
}
