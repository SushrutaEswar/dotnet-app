provider "aws" {
  region = "ap-south-1"
}

#################################################
# S3 Bucket for Pipeline Artifacts
#################################################

resource "aws_s3_bucket" "artifacts" {
  bucket = "dotnet-bluegreen-dotnet-app-20262805"
}

#################################################
# IAM ROLE FOR CODEPIPELINE
#################################################

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

resource "aws_iam_role_policy" "pipeline_policy" {
  name = "codepipeline-policy"
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:*",
          "codebuild:*",
          "codedeploy:*",
          "codestar-connections:UseConnection"
        ]

        Resource = "*"
      }
    ]
  })
}

#################################################
# IAM ROLE FOR CODEBUILD
#################################################

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

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:*",
          "s3:*"
        ]

        Resource = "*"
      }
    ]
  })
}

#################################################
# CODEBUILD PROJECT
#################################################

resource "aws_codebuild_project" "build" {
  name         = "dotnet-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "ap-south-1"
    }
  }

  source {
    type      = "CODEPIPELINE"
      }
}

#################################################
# CODEPIPELINE
#################################################

resource "aws_codepipeline" "pipeline" {
  name     = "dotnet-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  #################################################
  # SOURCE STAGE
  #################################################

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
        ConnectionArn    = "arn:aws:codeconnections:ap-south-1:693024458454:connection/71ecd025-95d6-40e1-a0e2-f00bb2088690"
        FullRepositoryId = "SushrutaEswar/dotnet-app"
        BranchName       = "main"
      }
    }
  }

  #################################################
  # BUILD STAGE
  #################################################

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }
}

