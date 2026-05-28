resource "aws_codedeploy_deployment_group" "dg" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "bluegreen-dg"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  autoscaling_groups = [
    aws_autoscaling_group.blue.name,
    aws_autoscaling_group.green.name
  ]

  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.blue.name
    }

    target_group_info {
      name = aws_lb_target_group.green.name
    }
  }

  auto_rollback_configuration {
    enabled = true

    events = [
      "DEPLOYMENT_FAILURE",
      "DEPLOYMENT_STOP_ON_ALARM",
      "DEPLOYMENT_STOP_ON_REQUEST"
    ]
  }
}