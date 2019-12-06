variable "env" {
  type = "string"
}

variable "appName" {
  type = "string"
}

variable "appPrefix" {
  type = "string"
}

variable "backPolicyArn" {
  type = "string"
}

variable "apiGatewayId" {
  type = "string"
}

module "governancePermisionDeveloper" {
  source = "./developer"
  appPrefix = "${var.appPrefix}"
  appName = "${var.appName}"
  env = "${var.env}"
  backPolicyArn = "${var.backPolicyArn}"
  apiGatewayID = "${var.apiGatewayId}"
}

module "governancePermisionQa" {
  source = "./tester"
  appPrefix = "${var.appPrefix}"
  appName = "${var.appName}"
  env = "${var.env}"
}