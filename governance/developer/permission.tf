variable "appPrefix" {
  type = "string"
}

variable "appName" {
  type = "string"
}

variable "env" {
  type = "string"
}

variable "apiGatewayID" {
  type = "string"
}

variable "backPolicyArn" {
  type = "string"
}

resource "aws_iam_group" "developGroup" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "team-${var.env}-${var.appName}"
  path = "/"
}

data "aws_iam_policy_document" "codecommitDataPolicy" {
  statement {
    sid = "codecommitAccess"
    actions = [
      "codecommit:List*"
    ]
    resources = ["*"]
  }
  statement {
    sid = "codecommitAccessDevelopBranch"
    actions = [
      "codecommit:Batch*",
      "codecommit:CancelUploadArchive",
      "codecommit:DescribePullRequestEvents",
      "codecommit:Get*",
      "codecommit:GitPull",
      "codecommit:CreatePullRequest",
      "codecommit:DeleteCommentContent",
      "codecommit:DeleteFile",
      "codecommit:GitPush",
      "codecommit:MergePullRequestByFastForward",
      "codecommit:PostCommentForComparedCommit",
      "codecommit:PostCommentForPullRequest",
      "codecommit:PostCommentReply",
      "codecommit:PutFile",
      "codecommit:UpdateComment",
      "codecommit:UpdatePullRequestDescription",
      "codecommit:UpdatePullRequestStatus",
      "codecommit:UpdatePullRequestTitle",
      "codecommit:UploadArchive",
      "codecommit:GetCommentsForPullRequest",
      "codecommit:GetPullRequest"
    ]
    resources = [
      "arn:aws:codecommit:*:*:*${var.appName}*"
    ]
    condition {
      test="StringLikeIfExists"
      variable="codecommit:References"
      values=[
        "refs/heads/develop"]
    }
  }
  statement {
    sid = "codecommitAccessFeatureBranch"
    actions = [
      "codecommit:Batch*",
      "codecommit:CancelUploadArchive",
      "codecommit:DescribePullRequestEvents",
      "codecommit:Get*",
      "codecommit:GitPull",
      "codecommit:CreatePullRequest",
      "codecommit:Delete*",
      "codecommit:GitPush",
      "codecommit:MergePullRequestByFastForward",
      "codecommit:Post*",
      "codecommit:PutFile",
      "codecommit:Update*",
    ]
    resources = [
      "arn:aws:codecommit:*:*:*${var.appName}*"
    ]
    condition {
      test="StringLikeIfExists"
      variable="codecommit:References"
      values=[
        "refs/heads/feature",
        "refs/heads/feature/*"]
    }
  }
}

resource "aws_iam_policy" "codecommitPolicy" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${var.appPrefix}-codecommit"
  path = "/"
  policy = "${data.aws_iam_policy_document.codecommitDataPolicy.json}"
}

resource "aws_iam_group_policy_attachment" "codecommitPolicyAttach" {
  count      = "${var.env=="dev" ? 1 : 0}"
  group      = "${aws_iam_group.developGroup.name}"
  policy_arn = "${aws_iam_policy.codecommitPolicy.arn}"
  depends_on = ["aws_iam_group.developGroup"]
}

data "aws_iam_policy_document" "lambdaDataPolicy" {
  statement {
    sid = "lambdaAccessFuntion"
    actions = [
      "lambda:InvokeFunction",
      "lambda:ListVersionsByFunction",
      "lambda:Get*",
      "lambda:ListAliases",
      "lambda:UpdateFunctionConfiguration",
      "lambda:InvokeAsync",
      "lambda:UpdateAlias",
      "lambda:UpdateFunctionCode",
      "lambda:ListTags",
      "lambda:PublishVersion",
      "lambda:CreateAlias"
    ]
    resources = [
      "arn:aws:lambda:*:*:function:*${var.appName}*"
    ]
  }
  statement {
    sid = "lambdaAccessList"
    actions = [
      "lambda:List*",
      "lambda:Get*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambdaPolicy" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${var.appPrefix}-lambda"
  path = "/"
  policy = "${data.aws_iam_policy_document.lambdaDataPolicy.json}"
}

resource "aws_iam_group_policy_attachment" "lambdaPolicyAttach" {
  count      = "${var.env=="dev" ? 1 : 0}"
  group      = "${aws_iam_group.developGroup.name}"
  policy_arn = "${aws_iam_policy.lambdaPolicy.arn}"
  depends_on = ["aws_iam_group.developGroup"]
}

data "aws_iam_policy_document" "apiGatewayDataPolicy" {
  statement {
    sid = "apiGatewayAccess"
    actions = [
      "apigateway:PUT",
      "apigateway:PATCH",
      "apigateway:POST",
      "apigateway:GET"
    ]
    resources = [
      "arn:aws:apigateway:*::/restapis/${var.apiGatewayID}/*"
    ]
  }
}

resource "aws_iam_policy" "apiGatewayPolicy" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${var.appPrefix}-apigateway"
  path = "/"
  policy = "${data.aws_iam_policy_document.apiGatewayDataPolicy.json}"
}

resource "aws_iam_group_policy_attachment" "apiGatewayPolicyAttach" {
  count      = "${var.env=="dev" ? 1 : 0}"
  group      = "${aws_iam_group.developGroup.name}"
  policy_arn = "${aws_iam_policy.apiGatewayPolicy.arn}"
  depends_on = ["aws_iam_group.developGroup"]
}

data "aws_iam_policy_document" "cloudwatchDataPolicy" {
  statement {
    sid = "cloudWatchListAccess"
    actions = [
      "logs:Describe*",
      "logs:List*"
    ]
    resources = ["*"]
  }
  statement {
    sid = "cloudWatchAccess"
    actions = [
      "logs:Get*",
      "logs:TestMetricFilter",
      "logs:FilterLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/*${var.appName}*:*:*",
      "arn:aws:logs:*:*:log-group:/aws/codebuild/*${var.appName}*:*:*"
    ]
  }
}

resource "aws_iam_policy" "cloudWatchPolicy" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${var.appPrefix}-cloudWatch"
  path = "/"
  policy = "${data.aws_iam_policy_document.cloudwatchDataPolicy.json}"
}

resource "aws_iam_group_policy_attachment" "cloudWatchPolicyAttach" {
  count      = "${var.env=="dev" ? 1 : 0}"
  group      = "${aws_iam_group.developGroup.name}"
  policy_arn = "${aws_iam_policy.cloudWatchPolicy.arn}"
  depends_on = ["aws_iam_group.developGroup"]
}

data "aws_iam_policy_document" "codepipelineDataPolicy" {
  statement {
    sid = "listAccess"
    actions = [
      "codepipeline:ListPipelines",
      "codebuild:ListBuilds",
      "codebuild:ListBuildsForProject",
      "codebuild:ListProjects",
      "codebuild:BatchGetProjects",
      "codebuild:BatchGetBuilds"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "codepipelineAccess"
    actions = [
      "codepipeline:GetPipeline",
      "codepipeline:GetPipelineState",
      "codepipeline:GetPipelineExecution",
      "codepipeline:ListPipelineExecutions",
      "codepipeline:ListActionTypes",
      "codepipeline:StartPipelineExecution"
    ]
    resources = [
      "arn:aws:codepipeline:*:*:${var.appPrefix}*"
    ]
  }
  statement {
    sid = "codebuildAccess"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:BatchGetProjects",
      "codebuild:ListConnectedOAuthAccounts",
      "codebuild:ListCuratedEnvironmentImages",
      "codebuild:ListRepositories"
    ]
    resources = [
      "arn:aws:codebuild:*:*:project/${var.appPrefix}*"
    ]
  }
}

resource "aws_iam_policy" "codepipelinePolicy" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${var.appPrefix}-codepipeline"
  path = "/"
  policy = "${data.aws_iam_policy_document.codepipelineDataPolicy.json}"
}

resource "aws_iam_group_policy_attachment" "codepipelinePolicyAttach" {
  count      = "${var.env=="dev" ? 1 : 0}"
  group      = "${aws_iam_group.developGroup.name}"
  policy_arn = "${aws_iam_policy.codepipelinePolicy.arn}"
  depends_on = ["aws_iam_group.developGroup"]
}

data "aws_iam_policy_document" "bucketsS3DataPolicy" {
  statement {
    sid = "listBucketsAccess"
    actions = [
      "s3:List*",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "bucketsAccess"
    actions = [
      "s3:Get*",
      "s3:Put*",
      "s3:DeleteObject*",
    ]
    resources = [
      "arn:aws:s3:::${var.appPrefix}*",
      "arn:aws:s3:::${var.appPrefix}*/*"
    ]
  }
}

resource "aws_iam_policy" "bucketsS3Policy" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${var.appPrefix}-s3-buckets"
  path = "/"
  policy = "${data.aws_iam_policy_document.bucketsS3DataPolicy.json}"
}

resource "aws_iam_group_policy_attachment" "bucketsS3PolicyAttach" {
  count      = "${var.env=="dev" ? 1 : 0}"
  group      = "${aws_iam_group.developGroup.name}"
  policy_arn = "${aws_iam_policy.bucketsS3Policy.arn}"
  depends_on = ["aws_iam_group.developGroup"]
}

data "aws_iam_policy_document" "parametersDataPolicy" {
  statement {
    sid = "listParametersAccess"
    actions = [
      "ssm:DescribeParameters",
      "kms:ListAliases"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "parametersAccess"
    actions = [
      "ssm:GetParameterHistory",
      "ssm:DescribeDocumentParameters",
      "ssm:GetParametersByPath",
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssm:DeleteParameter",
      "ssm:DeleteParameters"
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/tgr/${var.env}/${var.appName}/*"
    ]
  }
}

resource "aws_iam_policy" "parametersPolicy" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${var.appPrefix}-ssm-parameters"
  path = "/"
  policy = "${data.aws_iam_policy_document.parametersDataPolicy.json}"
}

resource "aws_iam_group_policy_attachment" "parametersPolicyAttach" {
  count      = "${var.env=="dev" ? 1 : 0}"
  group      = "${aws_iam_group.developGroup.name}"
  policy_arn = "${aws_iam_policy.parametersPolicy.arn}"
  depends_on = ["aws_iam_group.developGroup"]
}

data "aws_iam_policy_document" "backDataRole" {
  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backRole" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${var.appPrefix}-serverless-deploy-ec2"
  description = "Otorga privilegios para realizar deploy serverless en una instancia EC2"
  assume_role_policy = "${data.aws_iam_policy_document.backDataRole.json}"
  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }
}

resource "aws_iam_instance_profile" "backRoleProfile" {
  count = "${var.env=="dev" ? 1 : 0}"
  name = "${aws_iam_role.backRole.name}"
  role = "${aws_iam_role.backRole.name}"
}

resource "aws_iam_role_policy_attachment" "backRoleAttach" {
  count = "${var.env=="dev" ? 1 : 0}"
  role = "${aws_iam_role.backRole.name}"
  policy_arn = "${var.backPolicyArn}"
  depends_on = [
    "aws_iam_role.backRole"]
}









