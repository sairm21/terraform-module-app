resource "aws_security_group" "sg" {
  name        = "${var.component}-${var.env}-SG"
  description = "Allow ${var.component}-${var.env}-Traffic"
  vpc_id = var.vpc_id

  ingress {
    description      = "Allow inbound traffic for ${var.component}-${var.env}"
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = var.sg_subnets_cidr # to allow traffic only from internal LB
  }

  ingress {
    description      = "Allow inbound traffic for ${var.component}-${var.env}"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = var.bastion_host
  }

  ingress {
    description      = "Allow inbound traffic for ${var.component}-${var.env}"
    from_port        = 9100
    to_port          = 9100
    protocol         = "tcp"
    cidr_blocks      = var.allow_prometheus
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # to all all traffic
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({
    Name = "${var.env}-${var.component}-SG"
  },
    var.tags)
}

resource "aws_launch_template" "app_launch_template" {
  name = "${var.component}-${var.env}-launch-template"
/*
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
      encrypted = true
      kms_key_id = var.kms_key_id
    }
  }
*/
  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  image_id = data.aws_ami.ami.id

  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = merge({
      Name = "${var.env}-${var.component}", Monitor= "True"
    },
      var.tags)
  }

  user_data     = base64encode(templatefile("${path.module}/userdata.sh", {
    env = var.env
    component = title(var.component)

  }))

}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.component}-${var.env}-TG"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  deregistration_delay = 10

  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 6
    path = "/health"
    port = var.app_port
    protocol = "HTTP"
    timeout = 5
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = var.listener_arn
  priority     = var.lb_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  condition {
    host_header {
      values = ["${var.component}-${var.env}.iamadevopsengineer.tech"]
    }
  }
}


resource "aws_autoscaling_group" "app_ASG" {
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnets
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }
}

resource "aws_route53_record" "DNS" {
  zone_id = "Z07064001LQWEDMH2WVFL"
  name    = "${var.component}-${var.env}"
  type    = "CNAME"
  ttl     = 300
  records = [var.lb_dns_name]
}
