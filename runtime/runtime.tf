variable "env" {
  type = "string"
}

variable "appPrefix" {
  type = "string"
}

variable "appName" {
  type = "string"
}

variable "appFrontSubdomain" {
  type = "string"
}

variable "appFrontDomain" {
  type = "string"
}

variable "route53ZoneId" {
  type = "string"
}

variable "cognitoReadAttributes" {
  type = "list"
}

variable "cognitoPoolId" {
  type = "string"
}

variable "cognitoProviders" {
  type = "list"
}

variable "acmCertificateArn" {
  type = "string"
}

module "runtimeS3Buckets" {
  source = "./resource/s3"
  appPrefix = "${var.appPrefix}"
  appName = "${var.appName}"
  env = "${var.env}"
}

module "runtimeApiGateway" {
  source = "./resource/api-gateway"
  appPrefix = "${var.appPrefix}"
  env = "${var.env}"
}

module "runtimeCloudfront" {
  source = "./resource/cloudfront"
  appName = "${var.appName}"
  env = "${var.env}"
  frontBucketEndpoint = "${module.runtimeS3Buckets.frontBucketEndpoint}"
  acmCertificateArn = "${var.acmCertificateArn}"
  alias = "${var.appFrontSubdomain}.${var.appFrontDomain}"
}

module "runtimeRoute53" {
  source = "./resource/route53"
  cloudfrontDomainName = "${module.runtimeCloudfront.cloudfrontDomainName}"
  cloudfrontHostedZoneID = "${module.runtimeCloudfront.cloudfrontHostedZoneID}"
  subdomain = "${var.appFrontSubdomain}"
  domain = "${var.appFrontDomain}"
  route53ZoneID = "${var.route53ZoneId}"
}

module "runtimePermission" {
  source = "./permission"
  env = "${var.env}"
  appName = "${var.appName}"
  appPrefix = "${var.appPrefix}"
  frontBucketID = "${module.runtimeS3Buckets.frontBucketID}"
}

module "runtimeCognitoAppClients" {
  source = "./resource/cognito"
  appPrefix = "${var.appPrefix}"
  cloudfrontAlias = "${var.appFrontSubdomain}.${var.appFrontDomain}"
  cognitoReadAttributes = ["${var.cognitoReadAttributes}"]
  cognitoPoolID = "${var.cognitoPoolId}"
  cognitoProviders = ["${var.cognitoProviders}"]
}

output "cloudfrontDistributionID" {
  value = "${module.runtimeCloudfront.cloudfrontDistributionID}"
}

output "cloudfrontDomainName" {
  value = "${module.runtimeCloudfront.cloudfrontDomainName}"
}

output "cloudFrontHostedZoneID" {
  value = "${module.runtimeCloudfront.cloudfrontHostedZoneID}"
}

output "lambdaRoleArn" {
  value = "${module.runtimePermission.lambdaRoleArn}"
}

output "apiGatewayID" {
  value = "${module.runtimeApiGateway.apigatewayID}"
}

output "apiGatewayRootID" {
  value = "${module.runtimeApiGateway.apigatewayRootID}"
}

output "apigatewayEndpoint" {
  value = "${module.runtimeApiGateway.apigatewayEndpoint}"
}

output "frontBucketID" {
  value = "${module.runtimeS3Buckets.frontBucketID}"
}

output "cognitoClientID" {
  value = "${module.runtimeCognitoAppClients.cognitoClientID}"
}

output "cognitoRedirectUri" {
  value = "${module.runtimeCognitoAppClients.cognitoRedirectUri}"
}

output "cognitoLogoutUri" {
  value = "${module.runtimeCognitoAppClients.cognitoLogoutUri}"
}