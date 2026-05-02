# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU Utilisation"
          region = "eu-west-2"
          metrics = [["AWS/ECS", "CPUUtilization",
            "ClusterName", aws_ecs_cluster.main.name,
            "ServiceName", aws_ecs_service.main.name
          ]]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS Memory Utilisation"
          region = "eu-west-2"
          metrics = [["AWS/ECS", "MemoryUtilization",
            "ClusterName", aws_ecs_cluster.main.name,
            "ServiceName", aws_ecs_service.main.name
          ]]
          period = 300
          stat   = "Average"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = "eu-west-2"
          metrics = [["AWS/ApplicationELB", "RequestCount",
            "LoadBalancer", aws_lb.main.arn_suffix
          ]]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Target Response Time"
          region = "eu-west-2"
          metrics = [["AWS/ApplicationELB", "TargetResponseTime",
            "LoadBalancer", aws_lb.main.arn_suffix
          ]]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}

# SNS Topic for CloudWatch Alarms
resource "aws_sns_topic" "cloudwatch_alarms" {
  name = "${var.name_prefix}-cloudwatch-alarms"
  tags = var.common_tags
}

resource "aws_sns_topic_subscription" "cloudwatch_email" {
  topic_arn = aws_sns_topic.cloudwatch_alarms.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ECS CPU Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.name_prefix}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU utilisation above 80%"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  tags = var.common_tags
}

# ECS Memory Alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.name_prefix}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS memory utilisation above 80%"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  tags = var.common_tags
}

# ALB 5XX Error Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5XX errors above 10 in 5 minutes"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  tags = var.common_tags
}

# ALB Unhealthy Host Alarm
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "One or more ECS tasks are unhealthy"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.main.arn_suffix
  }

  tags = var.common_tags
}

# Lambda Error Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.name_prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Stock checker Lambda function errored"
  alarm_actions       = [aws_sns_topic.cloudwatch_alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.stock_checker.function_name
  }

  tags = var.common_tags
}