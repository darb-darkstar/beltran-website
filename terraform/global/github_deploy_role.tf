data "aws_iam_policy_document" "github_actions_assume_role" {
    statement {
        effect = "Allow"

        principals {
            type        = "Federated"
            identifiers = [data.aws_iam_openid_connect_provider.github.arn]
        }

        actions = ["sts:AssumeRoleWithWebIdentity"]



        condition {
            test     = "StringLike"
            variable = "token.actions.githubusercontent.com:sub"
            values   = ["repo:${var.github_username}/${var.github_repo}:ref:refs/heads/*"]
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
                "Resource": [
                    "arn:aws:s3:::brad-beltran-site/*",
                    "arn:aws:s3:::dev-brad-beltran-site/*",
                    "arn:aws:s3:::beltran-terraform-state"
                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:ListBucket"
                ]
                Resource = [
                    "arn:aws:s3:::brad-beltran-site/*",
                    "arn:aws:s3:::dev-brad-beltran-site/*",
                    "arn:aws:s3:::beltran-terraform-state"

                ]
            },
            {
                "Effect": "Allow",
                "Action": [
                    "cloudfront:CreateInvalidation"
                ],
                "Resource": "*"     
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "github_actions_attach" {
    role       = aws_iam_role.github_actions_role.name
    policy_arn = aws_iam_policy.github_deploy_policy.arn   
}