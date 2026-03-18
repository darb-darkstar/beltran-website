resource "aws_wafv2_web_acl" "dev_waf" {
    name        = "${var.environment}-web-acl"
    description = "Web ACL for ${var.environment}-${var.site_name}"
    scope       = "CLOUDFRONT"

    default_action {
        block {}
    }

    rule {
        name = "AllowSpecificIPs"
        priority = 1

        action {
            allow {}
        }

        statement{
            ip_set_reference_statement {
                arn = aws_wafv2_ip_set.allowed_ips.arn
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "AllowedIPs"
            sampled_requests_enabled   = true
        }
    }

    rule {
        name = "AWSManagedRulesCommonRuleSet"
        priority = 2

        override_action {
            none {}
        }

        statement {
            managed_rule_group_statement {
                name = "AWSManagedRulesCommonRuleSet"
                vendor_name = "AWS"
            }
        }

        visibility_config {
            cloudwatch_metrics_enabled = true
            metric_name                = "AWSRules"
            sampled_requests_enabled   = true
        }
    }

    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "devWAF"
        sampled_requests_enabled   = true
    }
}

resource "aws_wafv2_ip_set" "allowed_ips" {
    name        = "dev-allowed-ips"
    description = "IP set for ${var.environment}-${var.site_name}"
    scope       = "CLOUDFRONT"

    ip_address_version = "IPV4"

    addresses = var.allowed_ip_addresses

    tags = {
        Environment = var.environment
        Project     = var.site_name
    }
}

output "waf_arn" {
    value = aws_wafv2_web_acl.dev_waf.arn
    description = "ARN of the WAF Web ACL"
}