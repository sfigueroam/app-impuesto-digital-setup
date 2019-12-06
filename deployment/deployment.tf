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

variable "repositorySetup" {
  type = "string"
}

variable "apiGatewayID" {
  type = "string"
}

variable "apiGatewayRootID" {
  type = "string"
}

variable "frontBucketID" {
  type = "string"
}

variable "backApiEndpoint" {
  type = "string"
}

variable "lambdaRoleArn" {
  type = "string"
}

variable "cloudfrontDistributionID" {
  type = "string"
}

variable "cognitoContribLogoutURI" {
  type = "string"
}

variable "cognitoAuthorizeURL" {
  type = "string"
}

variable "cognitoLogoutURL" {
  type = "string"
}

variable "cognitoContribRedirectURI" {
  type = "string"
}

variable "cognitoContribClientId" {
  type = "string"
}

variable "cognitoPoolArn" {
  type = "string"
}

variable "kmsKeyDevQa" {
  type = "string"
  default = "arn:aws:kms:us-east-1:080540609156:key/b97e9595-822a-4c79-8c09-3eede504a639"
}

variable "kmsKeyProd" {
  type = "string"
  default = "arn:aws:kms:us-east-1:596659627869:key/f6a54825-c0a7-4900-8eed-2807422f294d"
}

variable "roleArnGetCodecommit" {
  type = "string"
  default = "arn:aws:iam::080540609156:role/tgr-dev-codepipelines-multi-cuenta"
  description = "Rol para obtener repositorio codecommit, y luego encriptarlo y dejarlo en S3, funciona para todos los ambientes"
}

data "aws_caller_identity" "getAccount" {}

locals {
  cBuildRole = "arn:aws:iam::${data.aws_caller_identity.getAccount.account_id}:role/tgr-${var.env}-project-setup-codebuild"
  cPipelineRole = "arn:aws:iam::${data.aws_caller_identity.getAccount.account_id}:role/tgr-${var.env}-project-setup-codepipeline"
  cPipelineBucket = "tgr-${var.env}-codepipelines"
  codecommitAccount = "080540609156"
}

module "deploymentPermission" {
  source = "./permission"
  appPrefix = "${var.appPrefix}"
  appName = "${var.appName}"
  env = "${var.env}"
  account = "${data.aws_caller_identity.getAccount.account_id}"
  apiGatewayID = "${var.apiGatewayID}"
}

module "deploymentCodepipelineApp" {
  source = "./codepipeline"
  env = "${var.env}"
  appName = "${var.appName}"
  appPrefix = "${var.appPrefix}"
  apiGatewayID = "${var.apiGatewayID}"
  apiGatewayRootID = "${var.apiGatewayRootID}"
  cBuildRoleBack = "${module.deploymentPermission.backRoleArn}"
  cBuildRoleFront = "${local.cBuildRole}"
  cPipelineRole = "${local.cPipelineRole}"
  cPipelineBucket = "${local.cPipelineBucket}"
  lambdaRoleArn = "${var.lambdaRoleArn}"
  repositoryApp = "${var.repositoryApp}"
  roleArnGetCodecommit = "${var.roleArnGetCodecommit}"
  kmsKey = "${var.env=="prod" ? var.kmsKeyProd : var.kmsKeyDevQa}"
  frontBucketID = "${var.frontBucketID}"
  backApiEndpoint = "${var.backApiEndpoint}"
  cloudfrontDistributionID = "${var.cloudfrontDistributionID}"
  cognitoLogoutURI = "${var.cognitoContribLogoutURI}"
  cognitoAuthorizeURL = "${var.cognitoAuthorizeURL}"
  cognitoLogoutURL = "${var.cognitoLogoutURL}"
  cognitoRedirectURI = "${var.cognitoContribRedirectURI}"
  cognitoClientId = "${var.cognitoContribClientId}"
  cognitoPoolArn = "${var.cognitoPoolArn}"
  codepipelineRunnerRoleArn = "${module.deploymentPermission.codepipelineRunnerRoleArn}"
  codecommitAccount = "${local.codecommitAccount}"
}

output "backRoleArn" {
  value = "${module.deploymentPermission.backRoleArn}"
}

output "backPolicyArn" {
  value = "${module.deploymentPermission.backPolicyArn}"
}

