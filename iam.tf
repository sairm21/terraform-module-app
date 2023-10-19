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
