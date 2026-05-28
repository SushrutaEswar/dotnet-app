############################################
# CODEPIPELINE + CODEBUILD + CODEDEPLOY
# BLUE/GREEN DEPLOYMENT FOR .NET API
############################################

#############################
# S3 ARTIFACT BUCKET
#############################

resource "aws_s3_bucket" "artifacts" {
  bucket = "dotnet-bluegreen-artifacts-demo-229475224571"
}

#############################
# CODEPIPELINE ROLE
#############################

resource "aws_iam_role" "pipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "pipeline_policy" {
  role       = aws_iam_role.pipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#############################
# CODEBUILD ROLE
#############################

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codebuild_policy" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

#############################
# CODEDEPLOY ROLE
#############################

resource "aws_iam_role" "codedeploy_role" {
  name = "codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

#############################
# CODEBUILD PROJECT
#############################

resource "aws_codebuild_project" "build" {
  name         = "dotnet-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image         = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type          = "LINUX_CONTAINER"

    environment_variable {
      name  = "DOTNET_CLI_TELEMETRY_OPTOUT"
      value = "1"
    }
  }

  source {
    type = "CODEPIPELINE"
  }
}

#############################
# CODEDEPLOY APPLICATION
#############################

resource "aws_codedeploy_app" "app" {
  name             = "dotnet-app"
  compute_platform = "Server"
}

#############################
# CODEDEPLOY DEPLOYMENT GROUP
#############################

resource "aws_codedeploy_deployment_group" "dg" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "dotnet-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  auto_rollback_configuration {
    enabled = true

    events = [
      "DEPLOYMENT_FAILURE"
    ]
  }

  blue_green_deployment_config {

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"

      termination_wait_time_in_minutes = 5
    }
  }

  load_balancer_info {

    target_group_pair_info {

      prod_traffic_route {
        listener_arns = [aws_lb_listener.front_end.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "dotnet-app"
    }
  }
}

#############################
# CODEPIPELINE
#############################

resource "aws_codepipeline" "pipeline" {

  name     = "dotnet-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  ################################
  # SOURCE STAGE
  ################################

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = "YOUR_CONNECTION_ARN"
        FullRepositoryId = "SushrutaEswar/dotnet-app"
        BranchName       = "main"
      }
    }
  }

  ################################
  # BUILD STAGE
  ################################

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  ################################
  # DEPLOY STAGE
  ################################

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToEC2"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = aws_codedeploy_app.app.name
        DeploymentGroupName = aws_codedeploy_deployment_group.dg.deployment_group_name
      }
    }
  }
}
