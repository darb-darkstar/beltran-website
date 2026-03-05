resource "aws_iam_openid_connect_provider" "github" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
    statement {
        effect = "Allow"

        principals {
            type        = "Federated"
            identifiers = [aws_iam_openid_connect_provider.github.arn]
        }

        actions = ["sts:AssumeRoleWithWebIdentity"]



        condition {
            test     = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values   = ["repo:${var.github_username}/${var.github_repo}:ref:refs/heads/${var.github_branch}"]
        }
   
        condition {
                test     = "StringEquals"
                variable = "token.actions.githubusercontent.com:aud"
                values   = ["sts.amazonaws.com"]
            }
    
    }

}

 resource "aws_iam_role" "github_actions_role" {
    name = "${var.site_name}-github-actions-role"
    assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

resource "aws_iam_policy" "github_deploy_policy" {
    name = "${var.site_name}-github-actions-policy"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            { 
                "Effect": "Allow",
                "Action": [
                    "s3:ListBucket"
                ],
                "Resource": aws_s3_bucket.website_bucket.arn
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:ListBucket"
                ]
                Resource = [
                    aws_s3_bucket.website_bucket.arn,
                    "${aws_s3_bucket.website_bucket.arn}/*"
                ]
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = aws_iam_policy.github_deploy_policy.arn   
}