resource "aws_s3_bucket" "secrets-efs" {
  bucket_prefix = "secret-efs-sync"
  acl    = "private"
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "secrets-efs" {
  bucket = aws_s3_bucket.secrets-efs.id

  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

resource "aws_efs_file_system" "secrets" {
  creation_token = var.efs_secrets
  encrypted = true
}

resource "aws_efs_access_point" "secrets-writer" {
  file_system_id = aws_efs_file_system.secrets.id

  root_directory {
    path = "/secrets"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 700
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }
}

resource "aws_efs_access_point" "riot-api-key" {
  file_system_id = aws_efs_file_system.secrets.id

  root_directory {
    path = "/secrets/riotapikey"
  }

  posix_user {
    gid = 1000
    uid = 1000
  }
}


resource "aws_efs_mount_target" "secrets" {
  file_system_id  = aws_efs_file_system.secrets.id
  subnet_id       = aws_subnet.player-data-lambdas.id
  security_groups = [aws_security_group.secrets-efs.id]
}

resource "aws_security_group" "secrets-efs-egress" {
  name        = "secrets-efs-egress"
  description = "SG For allowing traffic to EFS"
  vpc_id      = aws_vpc.get-players.id
  egress = [{
    security_groups = [aws_security_group.secrets-efs.id]
    cidr_blocks = []
    ipv6_cidr_blocks = []
    description = "Allow resources to mount EFS"
    protocol = "tcp"
    from_port = 2049
    to_port = 2049
    prefix_list_ids = []
    self = null
  }]
}

resource "aws_security_group" "secrets-efs" {
  name        = "secrets-efs"
  description = "SG For allowing traffic to EFS"
  vpc_id      = aws_vpc.get-players.id
}

resource "aws_security_group_rule" "secrets-efs-ingress" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  security_group_id = aws_security_group.secrets-efs.id
  source_security_group_id = aws_security_group.secrets-efs-egress.id
}

resource "aws_lambda_function" "syncEFSSecrets" {  
  function_name = "syncEFSSecrets"

  filename = "tmp/python_lambda.zip"

  runtime = "python3.9"
  handler = "main.lambda_handler"
  role    = aws_iam_role.lambda.arn
  timeout = 2

  file_system_config {
    arn = aws_efs_access_point.secrets-writer.arn
    local_mount_path = "/mnt/secrets"
  }

  vpc_config {
    subnet_ids         = [aws_subnet.player-data-lambdas.id]
    security_group_ids = [aws_security_group.secrets-efs-egress.id]
  }

  depends_on = [
    aws_efs_mount_target.secrets
  ]
}

resource "aws_iam_role_policy" "syncEFSSecrets" {
  name = "syncEFSSecrets"
  role = aws_iam_role.syncEFSSecrets.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.secrets-efs.arn}"
      },
      {
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.secrets-efs.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role" "syncEFSSecrets" {
  name = "syncEFSSecrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}
