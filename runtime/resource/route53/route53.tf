variable "subdomain" {
  type = "string"
}

variable "domain" {
  type = "string"
}

variable "route53ZoneID" {
  type = "string"
}

variable "cloudfrontDomainName" {
  type = "string"
}

variable "cloudfrontHostedZoneID" {
  type = "string"
}

resource "aws_route53_record" "subdomain" {
  zone_id = "${var.route53ZoneID}"
  name = "${var.subdomain}.${var.domain}"
  type = "A"

  alias {
    name = "${var.cloudfrontDomainName}"
    zone_id = "${var.cloudfrontHostedZoneID}"
    evaluate_target_health = true
  }
}