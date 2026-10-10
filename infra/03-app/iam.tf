# -----------------------------------------------------------------------------
# What the server is allowed to do.
#
# The server needs two powers, and nothing more:
#
#   1. Let you log in through Session Manager, so you get a shell in your
#      browser with no SSH keys and no open ports.
#   2. Read its own two secrets: the database password and the Yelp key.
#
# We grant those by attaching a ROLE to the machine. The server then gets
# temporary credentials automatically. There are no access keys anywhere in
# this course, which is exactly how it should be.
# -----------------------------------------------------------------------------

# "Who may use this role?" Answer: EC2 instances.
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "course-app-role"
  description        = "The app server: Session Manager access and read-only on its own secrets"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name = "course-app-role"
  }
}

# 1. Session Manager. This managed policy is written and maintained by AWS.
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 2. The two secrets, named one by one. The server cannot read any other
#    secret in your account, which is the whole idea of least privilege.
data "aws_iam_policy_document" "read_secrets" {
  statement {
    sid     = "ReadOwnSecrets"
    actions = ["secretsmanager:GetSecretValue"]

    resources = [
      local.db_secret_arn,
      local.yelp_secret_arn,
    ]
  }

  # Secrets are stored encrypted, so reading one also means decrypting it.
  # The condition limits this to decryption done on Secrets Manager's behalf.
  statement {
    sid       = "DecryptThroughSecretsManager"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "read_secrets" {
  name   = "course-app-read-secrets"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.read_secrets.json
}

# An instance profile is the wrapper that lets a role be attached to a server.
resource "aws_iam_instance_profile" "app" {
  name = "course-app-profile"
  role = aws_iam_role.app.name

  tags = {
    Name = "course-app-profile"
  }
}
