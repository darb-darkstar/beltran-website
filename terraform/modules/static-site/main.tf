
resource "aws_s3_bucket" "website_bucket" {
    bucket = var.environment == "prod" ? "brad-beltran-site" : "${var.environment}-brad-beltran-site"
    
    tags = var.tag
}

resource "aws_s3_object" "index" {
    bucket = aws_s3_bucket.website_bucket.id
    key    = "index.html"
    source = "${path.root}/../../../website/index.html"
    content_type = "text/html"
    etag = filemd5("${path.root}/../../../website/index.html")
}

resource "aws_s3_object" "error" {
    bucket = aws_s3_bucket.website_bucket.id
    key    = "error.html"
    source = "${path.root}/../../../website/error.html"
    content_type = "text/html"
    etag = filemd5("${path.root}/../../../website/error.html")

}

resource "aws_s3_bucket_public_access_block" "set" {
    bucket = aws_s3_bucket.website_bucket.id

    block_public_acls       = true
    block_public_policy     = false
    ignore_public_acls      = true
    restrict_public_buckets = false
}

data "aws_iam_policy_document" "site_policy" {
    
    statement {
        sid       = "AllowCloudFrontRead"

        actions   = ["s3:GetObject"]

        resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    
        principals {
            type        = "Service"
            identifiers = ["cloudfront.amazonaws.com"]
        }
    
        condition {
            test     = "StringEquals"
            variable = "AWS:SourceArn"
            values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"]
        }
    }

}

resource "aws_s3_bucket_policy" "cloudfront_policy" {
    bucket = aws_s3_bucket.website_bucket.id
    depends_on = [
        aws_cloudfront_distribution.cdn,
        aws_cloudfront_origin_access_control.oac,
        aws_s3_bucket_public_access_block.set
    ]

    policy = data.aws_iam_policy_document.site_policy.json
}



data "aws_cloudfront_cache_policy" "caching_optimized" {
    name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "cdn" {
    depends_on = [aws_acm_certificate_validation.cert_validation,
                   aws_wafv2_web_acl.dev_waf,
                   aws_wafv2_web_acl.prod_waf
    ]
    
    web_acl_id = var.environment == "prod" ? aws_wafv2_web_acl.prod_waf[0].arn : aws_wafv2_web_acl.dev_waf[0].arn

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

resource "aws_cloudfront_distribution" "apex_redirect" {
    count = var.environment == "prod" ? 1 : 0
    enabled = true
    aliases = [var.domain_name]

    origin {
        domain_name = aws_cloudfront_distribution.cdn.domain_name
        origin_id   = "redirect-origin"
    
    custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
    
    }
    }

    default_cache_behavior {
        target_origin_id       = "redirect-origin"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["GET", "HEAD"]
        cached_methods         = ["GET", "HEAD"]
        cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
        function_association {
            event_type   = "viewer-request"
            function_arn = aws_cloudfront_function.apex_redirect.arn
        }
    }

    

    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.cert.arn
        ssl_support_method  = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
       
}
    

    




resource "aws_cloudfront_origin_access_control" "oac" {
    name = "${var.site_name}-oac"
    description     = "OAC for ${var.site_name}"
    signing_behavior = "always"
    signing_protocol = "sigv4"
    origin_access_control_origin_type    = "s3"
    
}

resource "aws_acm_certificate" "cert" {
    provider = aws.us-east-1
    domain_name = "${var.subdomain}.${var.domain_name}"
    validation_method = "DNS"

    subject_alternative_names = ["${var.subdomain}.${var.domain_name}"]

    lifecycle {
        create_before_destroy = true
    }

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

resource "aws_route53_record" "cert_validation" {
    for_each = { 
        for dvo in aws_acm_certificate.cert.domain_validation_options : 
        dvo.domain_name => {
            name   = dvo.resource_record_name
            type   = dvo.resource_record_type
            record = dvo.resource_record_value
        }
    }

    zone_id = data.aws_route53_zone.primary.zone_id
    name    = each.value.name
    type    = each.value.type
    records = [each.value.record]
    ttl= 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
    provider = aws.us-east-1
    certificate_arn = aws_acm_certificate.cert.arn
    validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "website" {
    zone_id = data.aws_route53_zone.primary.zone_id
    name    = "${var.subdomain}.${var.domain_name}"
    type    = "A"
    alias {
        name                   = aws_cloudfront_distribution.cdn.domain_name
        zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
        evaluate_target_health = false
    }
}

data "aws_route53_zone" "primary" {
    name         = var.domain_name
    private_zone = false
}
data "aws_caller_identity" "current" {}

resource "aws_wafv2_ip_set" "allowed_ips" {
    provider = aws.us-east-1
    name        = "${var.environment}-allowed-ips"
    description = "IP set for ${var.environment}-${var.site_name}"
    scope       = "CLOUDFRONT"
    ip_address_version = "IPV4"
    addresses = [
        for ip in var.allowed_ips : "${ip}/32" 
   ]       
}

resource "aws_wafv2_web_acl" "dev_waf" {
    count = var.environment == "dev" ? 1 : 0
    provider = aws.us-east-1
    name        = "dev-waf"
    description = "WAF for ${var.environment}-${var.site_name}"
    scope       = "CLOUDFRONT"

    default_action {
        block {}
    }

    rule {
        name     = "AllowIPs"
        priority = 0

        action {
            allow {}
        }

        statement {
            ip_set_reference_statement {
                arn = aws_wafv2_ip_set.allowed_ips.arn
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "AllowIPs"
            sampled_requests_enabled   = true
        }
    }

    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "devWAF"
        sampled_requests_enabled   = true
    }
}

resource "aws_wafv2_web_acl" "prod_waf" {
    count = var.environment == "prod" ? 1 : 0
    provider = aws.us-east-1
    name        = "prod-waf"
    description = "WAF for ${var.environment}-${var.site_name}"
    scope       = "CLOUDFRONT"

    default_action {
        allow {}
    }

        rule {
        name     = "AllowIPs"
        priority = 0

        action {
            allow {}
         }

        statement {
            ip_set_reference_statement {
                arn = aws_wafv2_ip_set.allowed_ips.arn
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "AllowIPs"
            sampled_requests_enabled   = true
        }
    }

        rule {
        name = "RateLimit"
        priority = 1

        action {
            block {}
        }
        
        statement {
            rate_based_statement {
                limit = 1000
                aggregate_key_type = "IP"
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "RateLimit"
            sampled_requests_enabled   = true
        }
    }



    rule {
        name     = "AWSManagedRulesCommonRuleSet"
        priority = 2

        override_action {
            count {}
        }

        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesCommonRuleSet"
                vendor_name = "AWS"
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "CommonRuleSet"
            sampled_requests_enabled   = true
        }
    }

    rule {  
        name     = "AWSManagedRulesAmazonIpReputationList"
        priority = 3

        override_action {
            count {}
        }

        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesAmazonIpReputationList"
                vendor_name = "AWS"
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "AmazonIpReputationList"
            sampled_requests_enabled   = true
        }
    }

    rule {
        name     = "AWSManagedRulesKnownBadInputsRuleSet"
        priority = 4

        override_action {
            count {}
        }

        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesKnownBadInputsRuleSet"
                vendor_name = "AWS"
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "KnownBadInputsRuleSet"
            sampled_requests_enabled   = true
        }
    }

    # rule {
    #     name = "AWSManagedBotControlRuleSet"
    #     priority = 2
    #     override_action {
    #         none {}
    #     }
            
    #     statement {
    #         managed_rule_group_statement {
    #             name = "AWSManagedBotControlRuleSet"
    #             vendor_name = "AWS"

    #             managed_rule_group_configs {
    #                 aws_managed_rules_bot_control_rule_set {
    #                 inspection_level = "COMMON"
    #                 }
    #             }
            
    #         }
    #     }

    #     visibility_config {
    #         cloudwatch_metrics_enabled = true
    #         metric_name                = "BotControl"
    #         sampled_requests_enabled   = true
    #     }
        

    # }




    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "prodWAF"
        sampled_requests_enabled   = true
    }


}

resource "aws_wafv2_web_acl_logging_configuration" "prod_waf_logging" {
    count = local.enable_waf_logging ? 1 : 0
    depends_on = [aws_kinesis_firehose_delivery_stream.waf_logs_stream]
    provider = aws.us-east-1
    resource_arn = aws_wafv2_web_acl.prod_waf[0].arn

    log_destination_configs = [
        aws_kinesis_firehose_delivery_stream.waf_logs_stream[0].arn
    ]

    logging_filter {
        default_behavior = "DROP"

        filter {
            behavior = "KEEP"
            condition{
                action_condition {
                    action = "BLOCK"
                }
            }
            
            requirement = "MEETS_ANY"

        }
    }
    redacted_fields {
        single_header {
            name = "authorization"
        }
    
    }
}

resource "aws_s3_bucket" "waf_logs" {
    count = local.enable_waf_logging ? 1 : 0
    provider = aws.us-east-1
    bucket = "${var.environment}-${var.site_name}-waf-logs"
    acl = "private"

    tags = {
        Name = "${var.site_name}-waf-logs"
        Environment = var.environment
    }
}   

resource "aws_s3_bucket_versioning" "waf_logs_versioning" {
    count = local.enable_waf_logging ? 1 : 0

    provider = aws.us-east-1
    bucket = aws_s3_bucket.waf_logs[0].id
    versioning_configuration {
        status = "Enabled"
    }

}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs_lifecycle" {
    count = local.enable_waf_logging ? 1 : 0
    provider = aws.us-east-1
    bucket = aws_s3_bucket.waf_logs[0].id

    rule {
        id = "ExpireOldLogs"
        status = "Enabled"

        expiration {
            days = 30
        }
    }
}

resource "aws_iam_role" "firehose_role" {
    provider = aws.us-east-1
    name = "${var.environment}-waf-firehose-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Service = "firehose.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy" "firehose_policy" {
    count = local.enable_waf_logging ? 1 : 0
    provider = aws.us-east-1
    name = "${var.environment}-waf-firehose-policy"
    role = aws_iam_role.firehose_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:PutObject",
                    "s3:PutObjectAcl",
                ]
                Resource = [
                    aws_s3_bucket.waf_logs[0].arn,
                    "${aws_s3_bucket.waf_logs[0].arn}/*"
                ]
            }
        ]
    })
}

resource "aws_kinesis_firehose_delivery_stream" "waf_logs_stream" {
    count = local.enable_waf_logging ? 1 : 0
    provider = aws.us-east-1
    name = "aws-waf-logs-${var.environment}-${var.site_name}"
    destination = "extended_s3"

    extended_s3_configuration {
        role_arn = aws_iam_role.firehose_role.arn
        bucket_arn = aws_s3_bucket.waf_logs[0].arn
        prefix = "waf/"
        buffering_size = 5
        buffering_interval = 60
        compression_format = "GZIP"
    }
}