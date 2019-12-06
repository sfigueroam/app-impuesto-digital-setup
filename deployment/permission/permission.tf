variable "appPrefix" {
  type = "string"
}

variable "appName" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "account" {
  type = "string"
}

variable "apiGatewayID" {
  type = "string"
}

data "aws_caller_identity" "getAccount" {}

data "aws_iam_policy_document" "backDataPolicy" {
  statement {
    actions = [
      "cloudformation:CreateUploadBucket",
      "cloudformation:Describe*",
      "cloudformation:Get*",
      "cloudformation:List*",
      "cloudformation:ValidateTemplate",
      "lambda:CreateFunction",
      "lambda:ListFunctions",
      "lambda:ListVersionsByFunction",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:DeleteLogGroup",
      "logs:DeleteLogStream",
      "logs:PutLogEvents",
      "events:Put*",
      "events:DeleteRule",
      "events:DisableRule",
      "events:EnableRule",
      "events:Remove*",
      "events:DescribeRule",
      "events:DescribeEventBus",
      "s3:CreateBucket",
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:GetEncryptionConfiguration",
      "s3:PutEncryptionConfiguration",
      "kms:Decrypt",
      "kms:Encrypt"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "cloudformation:DeleteStack",
      "cloudformation:DescribeStackResource",
      "cloudformation:DescribeStackEvents",
      "cloudformation:DescribeStackResources",
      "cloudformation:CancelUpdateStack",
      "cloudformation:ContinueUpdateRollback",
      "cloudformation:GetStackPolicy",
      "cloudformation:GetTemplate",
      "cloudformation:UpdateStack",
      "cloudformation:UpdateTerminationProtection",
      "cloudformation:SignalResource",
      "cloudformation:CreateStack",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:DeleteRolePolicy",
      "iam:GetRole",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "lambda:UpdateFunctionCode",
      "lambda:UpdateFunctionConfiguration",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:cloudformation:*:*:stack/${var.appPrefix}*/*",
      "arn:aws:iam::*:role/${var.appPrefix}*",
      "arn:aws:s3:::${length(var.appPrefix)>=24 ? substr(var.appPrefix, 0, min(length(var.appPrefix), 24)) : var.appPrefix}*/*",
      "arn:aws:s3:::${length(var.appPrefix)>=24 ? substr(var.appPrefix, 0, min(length(var.appPrefix), 24)) : var.appPrefix}*",
      "arn:aws:lambda:us-east-1:*:function:${var.appPrefix}*"
    ]
  }
  statement {
    actions = [
      "apigateway:DELETE",
      "apigateway:HEAD",
      "apigateway:GET",
      "apigateway:OPTIONS",
      "apigateway:POST",
      "apigateway:PUT",
      "apigateway:PATCH"
    ]
    resources = [
      "arn:aws:apigateway:*::/restapis/${var.apiGatewayID}/*",
      "arn:aws:apigateway:*::/tags/*"
    ]
  }
  statement {
    actions = [
      "lambda:GetFunctionConfiguration",
      "s3:Get*",
      "s3:Put*",
      "s3:Delete*"
    ]
    resources = [
      "arn:aws:s3:::${length(var.appPrefix)>=24 ? substr(var.appPrefix, 0, min(length(var.appPrefix), 24)) : var.appPrefix}*",
      "arn:aws:s3:::${length(var.appPrefix)>=24 ? substr(var.appPrefix, 0, min(length(var.appPrefix), 24)) : var.appPrefix}*/*",
      "arn:aws:lambda:*:*:function:${var.appPrefix}*"
    ]
  }
  statement {
    actions = [
      "lambda:RemovePermission",
      "lambda:GetEventSourceMapping",
      "lambda:DeleteEventSourceMapping",
      "lambda:ListTags",
      "lambda:TagResource",
      "lambda:UntagResource"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:${var.appPrefix}*",
      "arn:aws:lambda:us-east-1:*:function:${var.appPrefix}*"

    ]
  }
  statement {
    actions = [
      "lambda:DeleteFunction"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:${var.appPrefix}*",
      "arn:aws:lambda:us-east-1:*:function:${var.appPrefix}*"

    ]
  }
  statement {
    actions = [
      "lambda:GetFunction"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:${var.appPrefix}*",
      "arn:aws:lambda:us-east-1:*:function:${var.appPrefix}*"

    ]
  }
  statement {
    actions = [
      "lambda:AddPermission"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:${var.appPrefix}*"
    ]
  }
  statement {
    actions = [
      "lambda:PublishVersion"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:${var.appPrefix}*"
    ]
  }
  statement {
    actions = [
      "ssm:GetParameters"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/tgr/${var.env}/${var.appName}/*"
    ]
  }
  statement {
    actions = [
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms"
    ]
    resources = [
      "arn:aws:cloudwatch:us-east-1:*:alarm:${var.appPrefix}*"
    ]
  }

  statement {
    actions = [
      "SNS:ListTopics"
    ]
    resources = [
      "arn:aws:sns:us-east-1:*:*"
    ]
  }

  statement {
    actions = [
      "SNS:*"
    ]
    resources = [
      "arn:aws:sns:us-east-1:*:${var.appPrefix}*"
    ]
  }

  statement {
    actions = [
      "events:*"
    ]
    resources = [
      "arn:aws:events:us-east-1:*:rule/${var.appPrefix}*"
    ]
  }

  statement {
    actions = [
      "logs:*"
    ]
    resources = [
      "arn:aws:logs:us-east-1:*:log-group:/aws/lambda/${var.appPrefix}*:log-stream:"
    ]
  }
}

resource "aws_iam_policy" "backPolicy" {
  name = "${var.appPrefix}-serverless-deploy"
  path = "/"
  policy = "${data.aws_iam_policy_document.backDataPolicy.json}"
}

data "aws_iam_policy_document" "servelessDataRole" {
  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backRole" {
  name = "${var.appPrefix}-codebuild-back-deployment"
  assume_role_policy = "${data.aws_iam_policy_document.servelessDataRole.json}"
  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }
}

resource "aws_iam_role_policy_attachment" "backRoleAttach" {
  role = "${aws_iam_role.backRole.name}"
  policy_arn = "${aws_iam_policy.backPolicy.arn}"
  depends_on = [
    "aws_iam_role.backRole"]
}

data "aws_iam_policy_document" "codepipelineRunnerDataPolicy" {
  statement {
    actions = [
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      "arn:aws:codepipeline:us-east-1:${var.account}:${var.appPrefix}*"
    ]
  }
}

resource "aws_iam_policy" "codepipelineRunnerPolicy" {
  name = "${var.appPrefix}-codepipeline-runner-role"
  path = "/"
  policy = "${data.aws_iam_policy_document.codepipelineRunnerDataPolicy.json}"
}

data "aws_iam_policy_document" "codepipelineRunnerDataRole" {
  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipelineRunnerRole" {
  name = "${var.appPrefix}-codepipeline-runner-role"
  description = "Otorga privilegios para correr un codepipeline"
  assume_role_policy = "${data.aws_iam_policy_document.codepipelineRunnerDataRole.json}"
  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }
}

resource "aws_iam_role_policy_attachment" "codepipelineRunnerRoleAttach" {
  role = "${aws_iam_role.codepipelineRunnerRole.name}"
  policy_arn = "${aws_iam_policy.codepipelineRunnerPolicy.arn}"
  depends_on = [
    "aws_iam_role.codepipelineRunnerRole"]
}

output "backPolicyArn" {
  value = "${aws_iam_policy.backPolicy.arn}"
}

output "backRoleArn" {
  value = "${aws_iam_role.backRole.arn}"
}

output "codepipelineRunnerRoleArn" {
  value = "${aws_iam_role.codepipelineRunnerRole.arn}"
}
