locals {
  s3OriginId = "web-root-$environment"
}

resource "aws_cloudfront_distribution" "this_environment" {
  enabled = true
  is_ipv6_enabled = true
  aliases = ["test.${var.DOMAIN_NAME}"]
  default_root_object = "index.html"
  http_version = "http2and3"

  origin {
    domain_name = aws_s3_bucket.web_root_test.bucket_regional_domain_name
    origin_id   = local.s3OriginId

#    s3_origin_config {
#      origin_access_identity = "origin-access-identity/cloudfront/ABCDEFG1234567"
#    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3OriginId
    compress = true

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
      headers = ["Origin"]
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 86400
    max_ttl = 31536000
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.test.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

data "aws_route53_zone" "public" {
  name = var.DOMAIN_NAME
}

resource "aws_route53_record" "this_environment" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "test.${var.DOMAIN_NAME}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this_environment.domain_name
    zone_id                = aws_cloudfront_distribution.this_environment.hosted_zone_id
    evaluate_target_health = true
  }
}

## Cloudfront distribution for main s3 site.
#resource "aws_cloudfront_distribution" "www_s3_distribution" {
#  origin {
#    domain_name = aws_s3_bucket.www_bucket.website_endpoint
#    origin_id = "S3-www.${var.bucket_name}"
#
#    custom_origin_config {
#      http_port = 80
#      https_port = 443
#      origin_protocol_policy = "http-only"
#      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
#    }
#  }
#
#  logging_config {
#    include_cookies = false
#    bucket          = "mylogs.s3.amazonaws.com"
#    prefix          = "myprefix"
#  }
#  aliases = [var.domain_name]

#  enabled = true
#  is_ipv6_enabled = true
#  default_root_object = "index.html"
#
#  aliases = ["www.${var.domain_name}"]
#
#  custom_error_response {
#    error_caching_min_ttl = 0
#    error_code = 404
#    response_code = 200
#    response_page_path = "/404.html"
#  }
#
#  default_cache_behavior {
#    allowed_methods = ["GET", "HEAD"]
#    cached_methods = ["GET", "HEAD"]
#    target_origin_id = "S3-www.${var.bucket_name}"
#
#    forwarded_values {
#      query_string = false
#
#      cookies {
#        forward = "none"
#      }
#    }
#
#    viewer_protocol_policy = "redirect-to-https"
#    min_ttl = 31536000
#    default_ttl = 31536000
#    max_ttl = 31536000
#    compress = true
#  }
#
#  restrictions {
#    geo_restriction {
#      restriction_type = "none"
#    }
#  }
#
#  viewer_certificate {
#    acm_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
#    ssl_support_method = "sni-only"
#    minimum_protocol_version = "TLSv1.1_2016"
#  }
#
#  tags = var.common_tags
#}

