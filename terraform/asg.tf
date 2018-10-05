resource "aws_elb" "webapp-elb" {
  name               = "webapp-elb"
  cross_zone_load_balancing   = true
  connection_draining         = true
  connection_draining_timeout = 300
  subnets            = ["${aws_subnet.public-subnet-az1.id}","${aws_subnet.public-subnet-az2.id}"]
  security_groups = ["${aws_security_group.elb-sg.id}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:80"
    interval            = 10
  }
}

resource "aws_security_group" "webapp-sg" {
  name        = "webapp_sg"
  description = "Allow traffic from load balancer, SSH and outbound"
  vpc_id      = "${aws_vpc.webapp-vpc.id}"
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_elb.webapp-elb.source_security_group_id}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role_policy" "ec2-webapp-iam-policy" {
  name = "ec2-webapp-iam-policy"
  role = "${aws_iam_role.ec2-webapp-iam-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "kms:Decrypt"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "ec2-webapp-iam-role" {
  name = "ec2-webapp-iam-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "webapp-instance-profile" {
  name = "ec2-webapp-iam-role"
  role = "${aws_iam_role.ec2-webapp-iam-role.name}"
}

resource "aws_security_group" "elb-sg" {
  name        = "elb_sg"
  description = "Allow HTTP traffic from Internet and outbound"
  vpc_id      = "${aws_vpc.webapp-vpc.id}"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
resource "aws_launch_configuration" "webapp-lc" {
  image_id      = "${var.ami}"
  instance_type = "t2.micro"
  iam_instance_profile = "${aws_iam_instance_profile.webapp-instance-profile.id}"
  security_groups = ["${aws_security_group.webapp-sg.id}"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "webapp-asg" {
  name                 = "webapp-asg - ${aws_launch_configuration.webapp-lc.name}"
  max_size             = "2"
  min_size             = "1"
  health_check_type = "EC2"
  health_check_grace_period = 150
  # Minimum of healthy instances before destroy old ASG
  wait_for_elb_capacity = "1"
  wait_for_capacity_timeout = "5m"
  launch_configuration = "${aws_launch_configuration.webapp-lc.id}"
  load_balancers       = ["${aws_elb.webapp-elb.name}"]
  vpc_zone_identifier  = ["${aws_subnet.public-subnet-az1.id}","${aws_subnet.public-subnet-az2.id}"]
  tag {
    key                 = "Name"
    value               = "webapp-asg"
    propagate_at_launch = "true"
  }
  # Creates a new ASG before destroy the old one
  lifecycle {
    create_before_destroy = true
  }
}
