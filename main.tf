resource "aws_iam_policy" "ssm_policy" {
  name        = "${var.component}-${var.env}-ssm-ps-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-ps-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": "arn:aws:ssm:us-east-1:804838709963:parameter/roboshop.${var.env}.${lower(var.component)}.*"
      }
    ]
  })
}


resource "aws_iam_role" "ec2_role" {
  name = "${var.component}-${var.env}-EC2-role"

 assume_role_policy = jsonencode({
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Principal": {
         "Service": "ec2.amazonaws.com"
       },
       "Action": "sts:AssumeRole"
     }
   ]
 })

 }

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.component}-${var.env}-EC2-profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}


resource "aws_security_group" "sg" {
  name        = "${var.component}-${var.env}-SG"
  description = "Allow ${var.component}-${var.env}-Traffic"

  ingress {
    description      = "Allow inbound traffic for ${var.component}-${var.env}"
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # allow all trafic
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}"
  }
}

resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3.small"
  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name # instance profile is used to attach a role to instance
  tags = {
    Name = "${var.component}-${var.env}"
  }
}

resource "aws_route53_record" "DNS" {
  zone_id = "Z07064001LQWEDMH2WVFL"
  name    = "${var.component}-dev"
  type    = "A"
  ttl     = 300
  records = [aws_instance.instance.private_ip]
}

resource "null_resource" "ansible_playbook" {
  depends_on = [aws_instance.instance, aws_route53_record.DNS]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.instance.public_ip
    }
    inline = [
      "sudo labauto ansible",
      "sudo set-hostname -skip-apply ${var.component}",
      "ansible-pull -i localhost, -U https://github.com/sairm21/roboshop-ansible-v1 -e env=${var.env} -e role_name=${var.component} main.yml"
    ]
  }
}