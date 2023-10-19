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

  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
      encrypted = true
      kms_key_id = var.kms_key_id
    }
  }

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
    component = var.component

  }))

}

resource "aws_autoscaling_group" "app_ASG" {
  desired_capacity   = var.desired_capacity
  max_size           = var.max_size
  min_size           = var.min_size
  vpc_zone_identifier = var.subnets

  launch_template {
    id      = aws_launch_template.app_launch_template.id
    version = "$Latest"
  }
}
/*
resource "aws_route53_record" "DNS" {
  zone_id = "Z07064001LQWEDMH2WVFL"
  name    = "${var.component}-dev"
  type    = "A"
  ttl     = 300
  records = [aws_instance.instance.private_ip]
}
*/