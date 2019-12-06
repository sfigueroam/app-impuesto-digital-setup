variable "appPrefix" {
  type = "string"
}
variable "appName" {
  type = "string"
}
variable "env" {
  type = "string"
}

resource "aws_s3_bucket" "frontBucket" {
  bucket = "${var.appPrefix}-front"
  acl = "public-read"
  versioning {
    enabled = false
  }
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  tags = {
    Application = "${var.appName}"
    Env = "${var.env}"
  }
}

output "frontBucketEndpoint" {
  value = "${aws_s3_bucket.frontBucket.website_endpoint}"
}

output "frontBucketID" {
  value = "${aws_s3_bucket.frontBucket.id}"
}

output "frontBucketArn" {
  value = "${aws_s3_bucket.frontBucket.arn}"
}