# SNS Topic for stock alerts
resource "aws_sns_topic" "stock_alerts" {
  name = "${var.name_prefix}-stock-alerts"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-stock-alerts"
  })
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.stock_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

# Lambda permissions — RDS access, SNS publish, CloudWatch logs
resource "aws_iam_role_policy" "lambda" {
  name = "${var.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.stock_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}

# Zip the Lambda function code
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.root}/../lambda/stock_checker.py"
  output_path = "${path.root}/../lambda/stock_checker.zip"
}

# Lambda Function
resource "aws_lambda_function" "stock_checker" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.name_prefix}-stock-checker"
  role             = aws_iam_role.lambda.arn
  handler          = "stock_checker.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout          = 30

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.ecs.id]
  }

  environment {
    variables = {
      DATABASE_URL  = var.db_url
      SNS_TOPIC_ARN = aws_sns_topic.stock_alerts.arn
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-stock-checker"
  })
}

# EventBridge rule — triggers Lambda every night at midnight
resource "aws_cloudwatch_event_rule" "nightly" {
  name                = "${var.name_prefix}-nightly-stock-check"
  description         = "Triggers stock checker Lambda every night at midnight"
  schedule_expression = "cron(0 0 * * ? *)"

  tags = var.common_tags
}

# EventBridge target — points rule at Lambda
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.nightly.name
  target_id = "StockCheckerLambda"
  arn       = aws_lambda_function.stock_checker.arn
}

# Allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stock_checker.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.nightly.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name_prefix}-stock-checker"
  retention_in_days = 30

  tags = var.common_tags
}