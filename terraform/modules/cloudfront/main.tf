resource "aws_cloudfront_distribution" "cdn" {
    depends_on = [aws_acm_certificate_validation.cert_validation]
    
    web_acl_id = aws_wafv2_web_acl.this.arn

    origin {
        domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
        origin_id   = "S3-${aws_s3_bucket.website_bucket.id}"
        origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    }

    enabled             = true
    comment             = "CDN for ${var.site_name}"
    default_root_object = "index.html"
    aliases             = ["${var.subdomain}.${var.domain_name}"]


    default_cache_behavior {
        target_origin_id       = "S3-${aws_s3_bucket.website_bucket.id}"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["GET", "HEAD"]
        cached_methods         = ["GET", "HEAD"]
        cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.cert.arn
        ssl_support_method  = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

    custom_error_response {
        error_code         = 403
        response_code      = 404
        response_page_path = "/../website/error.html"
    }

    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_cloudfront_origin_access_control" "oac" {
    name = "${var.site_name}-oac"
    description     = "OAC for ${var.site_name}"
    signing_behavior = "always"
    signing_protocol = "sigv4"
    origin_access_control_origin_type    = "s3"
    
}

resource "aws_cloudfront_function" "apex_redirect"  {
    name    = "${var.site_name}-apex-redirect"
    runtime = "cloudfront-js-1.0"
    code    = <<EOF
function handler(event) {
    var request = event.request;
    var host = request.headers.host.value;

    if (host === "${var.domain_name}") {
        var response = {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                "location": { "value": "https://${var.subdomain}.${var.domain_name}$"}
            }
        };
        return response;
    }
    EOF
}


data "aws_cloudfront_cache_policy" "caching_optimized" {
    name = "Managed-CachingOptimized"
}

