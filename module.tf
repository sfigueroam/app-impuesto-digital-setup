provider "aws" {
  region = "us-east-1"
  version = "~> 1.57"
}

variable "env" {
  type = "string"
}

variable "appName" {
  type = "string"
}

variable "cognitoProviders" {
  type = "list"
  default = ["ClaveUnica","ClaveTesoreria"]
}

variable "cognitoReadAttributes" {
  type = "list"
  default = ["custom:clave-unica:run,custom:clave-unica:name"]
}

variable "appFrontSubdomain" {
  type = "string"
  default = ""
}

variable "appFrontDomain" {
  type = "map"
  default = {
    "prod" = "tgr.cl"
    "dev" = "tegere.info"
    "qa" = "tegere.info"
  }
}

variable "route53ZoneId" {
  type = "map"
  default = {
    "prod" = "Z1X8JULZVP8EI3"
    "dev" = "Z3LEVMOFICGIN3"
    "qa" = "Z3LEVMOFICGIN3"
  }
}

variable "acmCertificateArn" {
  type = "map"
  default = {
    "prod" = "arn:aws:acm:us-east-1:596659627869:certificate/6324e7e9-2886-4f1f-8f24-57c8fdd9f63f"
    "dev" = "arn:aws:acm:us-east-1:080540609156:certificate/af13e4c6-dce2-4d15-897e-39e9be4bbc1f"
    "qa" = "arn:aws:acm:us-east-1:080540609156:certificate/af13e4c6-dce2-4d15-897e-39e9be4bbc1f"
  }
}

data "terraform_remote_state" "cognitoSetup" {
  backend = "s3"
  config {
    bucket  = "tgr-${var.env}-terraform-state"
    key     = "tgr-${var.env}-cognito-setup"
    region  = "us-east-1"
  }
}

data "terraform_remote_state" "cognitoAuthSetup" {
  backend = "s3"
  config {
    bucket  = "tgr-${var.env}-terraform-state"
    key     = "tgr-${var.env}-cognito-auth-setup"
    region  = "us-east-1"
  }
}

locals {
  appPrefix = "tgr-${var.env}-app-${var.appName}"
  repositoryApp = "app-${var.appName}-impl"
  repositorySetup = "app-${var.appName}-setup"
  subdomain = "${var.appName}-${var.env}"
  appFrontSubdomain = "${var.appFrontSubdomain==""? local.subdomain: var.appFrontSubdomain}"
  codecommitAcount = "080540609156"
}

module "runtime" {
  source = "./runtime"
  appPrefix = "${local.appPrefix}"
  appName = "${var.appName}"
  env = "${var.env}"
  appFrontSubdomain = "${local.appFrontSubdomain}"
  appFrontDomain = "${var.appFrontDomain[var.env]}"
  acmCertificateArn = "${var.acmCertificateArn[var.env]}"
  route53ZoneId = "${var.route53ZoneId[var.env]}"
  cognitoPoolId = "${data.terraform_remote_state.cognitoSetup.mainUserPoolId}"
  cognitoReadAttributes = ["${var.cognitoReadAttributes}"]
  cognitoProviders = ["${var.cognitoProviders}"]
}

module "governance" {
  source = "./governance"
  appPrefix = "${local.appPrefix}"
  appName = "${var.appName}"
  env = "${var.env}"
  apiGatewayId = "${module.runtime.apiGatewayID}"
  backPolicyArn = "${module.deployment.backPolicyArn}"
}

module "deployment" {
  source = "./deployment"
  appPrefix = "${local.appPrefix}"
  appName = "${var.appName}"
  env = "${var.env}"
  apiGatewayID = "${module.runtime.apiGatewayID}"
  apiGatewayRootID = "${module.runtime.apiGatewayRootID}"
  frontBucketID = "${module.runtime.frontBucketID}"
  lambdaRoleArn = "${module.runtime.lambdaRoleArn}"
  repositoryApp = "${local.repositoryApp}"
  repositorySetup = "${local.repositorySetup}"
  backApiEndpoint = "${module.runtime.apigatewayEndpoint}"
  cloudfrontDistributionID = "${module.runtime.cloudfrontDistributionID}"
  cognitoContribRedirectURI = "${module.runtime.cognitoRedirectUri}"
  cognitoContribClientId = "${module.runtime.cognitoClientID}"
  cognitoAuthorizeURL = "${data.terraform_remote_state.cognitoAuthSetup.authorizeURL}"
  cognitoContribLogoutURI = "${module.runtime.cognitoLogoutUri}"
  cognitoLogoutURL = "${data.terraform_remote_state.cognitoAuthSetup.logoutURL}"
  cognitoPoolArn = "${data.terraform_remote_state.cognitoSetup.mainUserPoolArn}"
}

terraform {
  backend "s3" {
    encrypt = false
    region = "us-east-1"
  }
}