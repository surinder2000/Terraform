provider "aws" {
    region = "ap-south-1"
    profile = "myprofile"
}

resource "aws_s3_bucket" "webBucket" {
    bucket = "surin-bucket"
    acl    = "private"

    tags = {
        Name  = "My bucket"
    }
}

locals {
    s3_origin_id = "S3-surin-bucket"
}
resource "aws_cloudfront_origin_access_identity" "originAccessIdentity" {
    comment = "access-identity-surin-bucket"
}

resource "aws_cloudfront_distribution" "s3Distribution" {
    origin {
        domain_name = aws_s3_bucket.webBucket.bucket_regional_domain_name
        origin_id   = local.s3_origin_id

    s3_origin_config {
        origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.originAccessIdentity.id}"
    }
}

    enabled             = true
    is_ipv6_enabled     = true

    default_cache_behavior {
        allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    }

    wait_for_deployment = false
    restrictions {
        geo_restriction {
            restriction_type = "whitelist"
            locations        = ["US", "CA", "IN"]
        }
    }

    tags = {
        Environment = "Production"
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }
    depends_on = [
        aws_cloudfront_origin_access_identity.originAccessIdentity
    ]
  
}

data "aws_iam_policy_document" "s3Policy" {
    statement {
        actions   = ["s3:GetObject"]
        resources = ["${aws_s3_bucket.webBucket.arn}/*"]

        principals {
            type        = "AWS"
            identifiers = ["${aws_cloudfront_origin_access_identity.originAccessIdentity.iam_arn}"]
        }
    }

    statement {
        actions   = ["s3:ListBucket"]
        resources = ["${aws_s3_bucket.webBucket.arn}"]

        principals {
            type        = "AWS"
            identifiers = ["${aws_cloudfront_origin_access_identity.originAccessIdentity.iam_arn}"]
        }
    }
}

resource "aws_s3_bucket_policy" "bucketReadPolicy" {
    bucket = aws_s3_bucket.webBucket.id
    policy = data.aws_iam_policy_document.s3Policy.json
}