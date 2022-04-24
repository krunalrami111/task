#Launch Template
resource "aws_launch_template" "launchtemp1" {
  name_prefix   = "launchtemp1"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = var.keyname
   user_data = filebase64("nginx.sh")
}
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["*ubuntu-*"]
  }
  filter {
  name   = "virtualization-type"
  values = ["hvm"]
  }
  owners = ["099720109477"]
}
# AutoScaling
resource "aws_autoscaling_group" "asg" {
  launch_template { 
      id    = aws_launch_template.launchtemp1.id
      version = "$Latest"
      }
  min_size = 2
  max_size = 10
  health_check_grace_period = 60
  desired_capacity          = 2
  force_delete  = true 
  health_check_type = "ELB"
  vpc_zone_identifier       = ["${aws_subnet.private-1.id}","${aws_subnet.private-2.id}"]
  target_group_arns = [aws_alb_target_group.tggroup.arn] 
  tag {
    key = "name"
    value = "terraform-asg"
    propagate_at_launch = true
   
  }
}


## Security Group for alb
resource "aws_security_group" "albsg" {
  name = "terraform-albsg"
  vpc_id    = aws_vpc.demo_vpc.id
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Load Balancer
resource "aws_alb" "terralb" {
  name            = "terraform-alb"
  security_groups = ["${aws_security_group.albsg.id}"]
  subnets         = ["${aws_subnet.private-1.id}","${aws_subnet.private-2.id}"]
}

resource "aws_alb_target_group" "tggroup" {
  name     = "terraform-alb-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.demo_vpc.id}"
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/index.html"
    port = 80
  }
}

resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.terralb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.tggroup.arn}"
    type             = "forward"
  }
}

#SNS
resource "aws_sns_topic" "alertsns" {
  name = var.sns_name
}

resource "aws_sns_topic_policy" "my_sns_topic_policy" {
  arn = aws_sns_topic.alertsns.arn
  policy = data.aws_iam_policy_document.my_custom_sns_policy_document.json
}

data "aws_iam_policy_document" "my_custom_sns_policy_document" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        var.account_id,
      ]
    }

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.alertsns.arn,
    ]

    sid = "__default_statement_ID"
  }
}

#Cloudwatch
resource "aws_cloudwatch_metric_alarm" "cpu-alarm" {
  alarm_name = "cpu_utliazation_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "70"
dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.asg.name}"
  }
alarm_description = "This metric monitor EC2 instance CPU utilization"
  alarm_actions = [aws_sns_topic.alertsns.arn]

}

#RDS
resource "aws_db_instance" "demodata" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = "abc"
  password             = "abc123456789"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}
