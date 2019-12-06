variable "env" {
  type = "string"
}

variable "appName" {
  type = "string"
}

variable "appPrefix" {
  type = "string"
}

variable "frontBucketID" {
  type = "string"
}

data "aws_iam_policy_document" "cloudwatchDataPolicy" {
  statement {
    sid = "putLogsEventsCloudWatch"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/*:*:*"]
  }
  statement {
    sid = "CreateLogsCloudWatch"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/*:*"]
  }
}

resource "aws_iam_policy" "cloudwatchPolicy" {
  name = "${var.appPrefix}-cloudwatch-logs"
  path = "/"
  description = "Otorga privilegios para la creacion de logs CloudWatch"
  policy = "${data.aws_iam_policy_document.cloudwatchDataPolicy.json}"
}

data "aws_iam_policy_document" "bucketDataPolicy" {
  statement {
    sid = "accessObjetsS3Bucket"
    actions = [
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:DeleteObject*"
    ]
    resources = [
      "arn:aws:s3:::${var.frontBucketID}/*",
      "arn:aws:s3:::${var.frontBucketID}"]
  }
}

resource "aws_iam_policy" "bucketPolicy" {
  name = "${var.appPrefix}-s3"
  path = "/"
  description = "Otorga privilegios sobre los bucket del proyecto"
  policy = "${data.aws_iam_policy_document.bucketDataPolicy.json}"
}

data "aws_iam_policy_document" "lambdaDataPolicy" {
  statement {
    sid = "lambda"
    actions = [
      "lambda:*"
    ]
    resources = [
      "arn:aws:lambda:us-east-1:*:function:${var.appPrefix}*",
      "arn:aws:lambda:us-east-1:*:function:tgr-${var.env}-log-analytics-cloudwatch-to-elasticsearch"
    ]
  }
}

resource "aws_iam_policy" "lambdaPolicy" {
  name = "${var.appPrefix}-back-lambda"
  path = "/"
  description = "Otorga privilegios de ejecución de lambdas"
  policy = "${data.aws_iam_policy_document.lambdaDataPolicy.json}"
}

data "aws_iam_policy_document" "lambdaDataRole" {
  statement {
    actions = [
      "sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambdaRole" {
  name = "${var.appPrefix}-back-lambda"
  assume_role_policy = "${data.aws_iam_policy_document.lambdaDataRole.json}"
  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatchRoleAttach" {
  role = "${aws_iam_role.lambdaRole.name}"
  policy_arn = "${aws_iam_policy.cloudwatchPolicy.arn}"
  depends_on = [
    "aws_iam_role.lambdaRole"]
}

resource "aws_iam_role_policy_attachment" "bucketsRoleAttach" {
  role = "${aws_iam_role.lambdaRole.name}"
  policy_arn = "${aws_iam_policy.bucketPolicy.arn}"
  depends_on = [
    "aws_iam_role.lambdaRole"]
}

resource "aws_iam_role_policy_attachment" "lambdaRoleAttach" {
  role = "${aws_iam_role.lambdaRole.name}"
  policy_arn = "${aws_iam_policy.lambdaPolicy.arn}"
  depends_on = [
    "aws_iam_role.lambdaRole"]
}

output "lambdaRoleArn" {
  value = "${aws_iam_role.lambdaRole.arn}"
}