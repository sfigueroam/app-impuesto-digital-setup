
variable "env" {
  type = "string"
}

variable "appName" {
  type = "string"
}

variable "appPrefix" {
  type = "string"
}

variable "repositoryApp" {
  type = "string"
}

variable "cBuildRoleBack" {
  type = "string"
}

variable "cBuildRoleFront" {
  type = "string"
}

variable "cPipelineRole" {
  type = "string"
}

variable "cPipelineBucket" {
  type = "string"
}

variable "apiGatewayID" {
  type = "string"
}

variable "apiGatewayRootID" {
  type = "string"
}

variable "lambdaRoleArn" {
  type = "string"
}

variable "kmsKey" {
  type = "string"
}

variable "roleArnGetCodecommit" {
  type = "string"
}

variable "frontBucketID" {
  type = "string"
}

variable "backApiEndpoint" {
  type = "string"
}

variable "cloudfrontDistributionID" {
  type = "string"
}

variable "cognitoAuthorizeURL" {
  type = "string"
}

variable "cognitoLogoutURL" {
  type = "string"
}

variable "cognitoClientId" {
  type = "string"
}

variable "cognitoRedirectURI" {
  type = "string"
}

variable "cognitoLogoutURI" {
  type = "string"
}

variable "cognitoPoolArn" {
  type = "string"
}

variable "codepipelineRunnerRoleArn" {
  type = "string"
}

variable "codecommitAccount" {
  type = "string"
}

variable "branch" {
  type = "map"
  default = {
    "prod" = "master"
    "dev" = "develop"
    "qa" = "release"
  }
}

################################### parameters ssm ###################################
########## Definicion de parametros requeridos por codebuild front y back ############

resource "aws_ssm_parameter" "defaultParameterBack" {
  name  = "/tgr/${var.env}/${var.appName}/back/default/parameter"
  type  = "String"
  value = "default_value"
  lifecycle {
    ignore_changes = [ "value" ]
  }
  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }
}

resource "aws_ssm_parameter" "defaultParameterFront" {
  name  = "/tgr/${var.env}/${var.appName}/front/default/parameter"
  type  = "String"
  value = "default_value"
  lifecycle {
    ignore_changes = [ "value" ]
  }
  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }
}

######################################################################################

resource "aws_codebuild_project" "codebuildBack" {
  name = "${var.appPrefix}-back"
  build_timeout = "15"
  service_role = "${var.cBuildRoleBack}"
  encryption_key = "${var.kmsKey}"
  cache {
    type = "NO_CACHE"
  }
    
  artifacts {
    type = "CODEPIPELINE"
  }
  
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/nodejs:8.11.0"
    type = "LINUX_CONTAINER"

    environment_variable =
                      [
                        {
                          name = "BUILD_ENV"
                          value = "${var.env}"
                        },
                        {
                          name = "BUILD_LAMBDA_ROLE_ARN"
                          value = "${var.lambdaRoleArn}"
                        },
                        {
                          name = "BUILD_API_ID"
                          value = "${var.apiGatewayID}"
                        },
                        {
                          name = "BUILD_API_ROOT_ID"
                          value = "${var.apiGatewayRootID}"
                        }
                      ]

  }
  source {
    type = "CODEPIPELINE"
    buildspec = "back/buildspec.yml"
  }
  
  tags = {
    Application = "${var.appName}"
	Env = "${var.env}"
  }

}

resource "aws_codebuild_project" "codebuildFront" {
  name = "${var.appPrefix}-front"
  build_timeout = "15"
  service_role = "${var.cBuildRoleFront}"
  encryption_key = "${var.kmsKey}"

  cache {
    type = "NO_CACHE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:8.11.0"
    type         = "LINUX_CONTAINER"
    environment_variable =
                        [
                          {
                            name = "S3_BUCKET"
                            value = "${var.frontBucketID}"
                          },
                          {
                            name = "BUILD_AUTH_AUTHORIZE_URL"
                            value = "${var.cognitoAuthorizeURL}"
                          },
                          {
                            name = "BUILD_AUTH_LOGOUT_URL"
                            value = "${var.cognitoLogoutURL}"
                          },
                          {
                            name = "BUILD_AUTH_CLIENT_ID"
                            value = "${var.cognitoClientId}"
                          },
                          {
                            name = "BUILD_APP_REDIRECT_LOGIN_URL"
                            value = "${var.cognitoRedirectURI}"
                          },
                          {
                            name = "BUILD_APP_REDIRECT_LOGOUT_URL"
                            value = "${var.cognitoLogoutURI}"
                          },
                          {
                            name = "BUILD_COGNITO_POOL_ARN"
                            value = "${var.cognitoPoolArn}"
                          }
                        ]
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "front/buildspec.yml"
  }

  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }

}

resource "aws_codebuild_project" "codebuildCloudfront" {
  name = "${var.appPrefix}-cloudfront"
  build_timeout = "15"
  service_role = "${var.cBuildRoleFront}"
  encryption_key = "${var.kmsKey}"

  cache {
    type = "NO_CACHE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/nodejs:8.11.0"
    type         = "LINUX_CONTAINER"
    environment_variable =
    [
      {
        name = "S3_BUCKET"
        value = "${var.frontBucketID}"
      },
      {
        name = "BUILD_CLOUDFRONT_ID"
        value = "${var.cloudfrontDistributionID}"
      }
    ]
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "${file("${path.module}/buildspecs/buildspec-front-invalidate.yml")}"
  }

  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }
}

resource "aws_codepipeline" "codepipelineApp" {
  name = "${var.appPrefix}"
  role_arn = "${var.cPipelineRole}"

  stage {
    name = "Source"

    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      provider = "CodeCommit"
      version = "1"
      role_arn = "${var.roleArnGetCodecommit}"
      output_artifacts = ["Source"]
      
      configuration {
        RepositoryName = "${var.repositoryApp}"
        BranchName = "${var.branch[var.env]}"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name = "Build-Back"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["Source"]

      configuration {
        ProjectName = "${aws_codebuild_project.codebuildBack.name}"
      }
    }

    action {
      name = "Build-Front"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["Source"]

      configuration {
        ProjectName = "${aws_codebuild_project.codebuildFront.name}"
      }
    }
  }

  stage {
    name = "Cloudfront"

    action {
      name = "Cloudfront-Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["Source"]

      configuration {
        ProjectName = "${aws_codebuild_project.codebuildCloudfront.name}"
      }
    }
  }

  artifact_store {
	location       = "${var.cPipelineBucket}"
	type           = "S3"
	encryption_key = {
      id = "${var.kmsKey}"
      type = "KMS"
	}
  }
}

data "template_file" "sourceEventTemplate" {
  template = "${file("deployment/codepipeline/steps-source-event.json")}"
  vars {
    repositoryArn = "arn:aws:codecommit:us-east-1:${var.codecommitAccount}:${var.repositoryApp}"
    branchName = "${var.branch[var.env]}"
  }
}

resource "aws_cloudwatch_event_rule" "sourceEvent" {
  name = "${var.appPrefix}-impl-source-change"
  event_pattern = "${data.template_file.sourceEventTemplate.rendered}"
}

resource "aws_cloudwatch_event_target" "stepsSourceEventTarget" {
  rule = "${aws_cloudwatch_event_rule.sourceEvent.name}"
  target_id = "StartCodepipeline"
  role_arn = "${var.codepipelineRunnerRoleArn}"
  arn = "${aws_codepipeline.codepipelineApp.arn}"
}
