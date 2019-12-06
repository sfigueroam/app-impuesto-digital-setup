variable "env" {
  type = "string"
}

variable "appPrefix" {
  type = "string"
}

data "aws_region" "getRegionData" {}

resource "aws_api_gateway_rest_api" "apigatewayBack" {
  name = "${var.appPrefix}-back"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

output "apigatewayID" {
  value = "${aws_api_gateway_rest_api.apigatewayBack.id}"
}

output "apigatewayRootID" {
  value = "${aws_api_gateway_rest_api.apigatewayBack.root_resource_id}"
}

output "apigatewayEndpoint" {
  value = "https://${aws_api_gateway_rest_api.apigatewayBack.id}.execute-api.${data.aws_region.getRegionData.name}.amazonaws.com/${var.env}"
}