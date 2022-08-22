resource "aws_lambda_function" "this" {
  function_name = var.lambda_name
  role          = aws_iam_role.exec_role.arn
  package_type  = "Image"
  timeout       = 10
  image_uri     = var.lambda_ecr_uri
}

resource "aws_iam_policy" "lambda_logging" {
  name   = "lambda_logging"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role" "exec_role" {
  name               = "${var.lambda_name}-exec-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "logs" {

  statement {
    sid    = "AllowCreatingLogGroups"
    effect = "Allow"

    resources = [
      "arn:aws:logs:*:*:*"
    ]

    actions = [
      "logs:CreateLogGroup"
    ]
  }

  statement {
    sid    = "AllowWritingLogs"
    effect = "Allow"

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/*:*"
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_iam_policy" "log" {
  name   = "${var.lambda_name}-log-policy"
  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_role_policy_attachment" "log_policy" {
  policy_arn = aws_iam_policy.log.arn
  role       = aws_iam_role.exec_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  policy_arn = aws_iam_policy.lambda_logging.arn
  role       = aws_iam_role.exec_role.name
}

data "aws_iam_policy" "ec2_full" {
  name = "AmazonEC2FullAccess"
}

data "aws_iam_policy" "asg_full" {
  name = "SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "ec2_full" {
  policy_arn = data.aws_iam_policy.ec2_full.arn
  role       = aws_iam_role.exec_role.name
}

resource "aws_iam_role_policy_attachment" "asg_full" {
  policy_arn = data.aws_iam_policy.asg_full.arn
  role       = aws_iam_role.exec_role.name
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_arn
}
