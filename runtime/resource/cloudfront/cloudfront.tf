variable "env" {
  type = "string"
}

variable "appName" {
  type = "string"
}

variable "frontBucketEndpoint" {
  type = "string"
}

variable "acmCertificateArn" {
  type = "string"
}

variable "alias" {
  type = "string"
}

resource "aws_cloudfront_distribution" "cloudfrontDistributionS3Front" {

  origin {
    domain_name = "${var.frontBucketEndpoint}"
    origin_id   = "${var.frontBucketEndpoint}"

    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  price_class = "PriceClass_All"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${var.frontBucketEndpoint}"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 31536000

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  custom_error_response {
    error_code = 404
    error_caching_min_ttl = 300
    response_code = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code = 403
    error_caching_min_ttl = 300
    response_code = 200
    response_page_path = "/index.html"
  }

  aliases = [
    "${var.alias}"
  ]
  viewer_certificate {
    acm_certificate_arn = "${var.acmCertificateArn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Application = "${var.appName}"
    Env         = "${var.env}"
  }
}

output "cloudfrontDomainName" {
  value = "${aws_cloudfront_distribution.cloudfrontDistributionS3Front.domain_name}"
}

output "cloudfrontHostedZoneID" {
  value = "${aws_cloudfront_distribution.cloudfrontDistributionS3Front.hosted_zone_id}"
}

output "cloudfrontDistributionID" {
  value = "${aws_cloudfront_distribution.cloudfrontDistributionS3Front.id}"
}