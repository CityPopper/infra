resource "aws_s3_bucket" "secrets-efs" {
  bucket_prefix = "secret-efs-sync"
  acl    = "private"
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_policy" "syncEFSSecrets" {
  bucket = "${aws_s3_bucket.secrets-efs.id}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [ 
      {
        Effect = "Allow"
        Principal = {
          "AWS": "${aws_iam_role.syncEFSSecrets-datasync.arn}",
        }
        Action = "s3:*"
        Resource = [
                    "${aws_s3_bucket.secrets-efs.arn}", 
                    "${aws_s3_bucket.secrets-efs.arn}/*"
                   ]
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "secrets-efs" {
  bucket = "${aws_s3_bucket.secrets-efs.id}"

  block_public_acls   = true
  block_public_policy = true
  restrict_public_buckets = true
  ignore_public_acls = true
}

resource "aws_efs_file_system" "secrets" {
  creation_token = "${var.efs_secrets}"
  encrypted = true
}

resource "aws_efs_access_point" "riot-api-key" {
  file_system_id = aws_efs_file_system.secrets.id

  root_directory {
    path = "/secrets/riotapikey"
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

resource "aws_efs_mount_target" "secrets" {
  file_system_id  = "${aws_efs_file_system.secrets.id}"
  subnet_id       = "${aws_subnet.player-data-lambdas.id}"
  security_groups = ["${aws_security_group.secrets-efs.id}"]
}

resource "aws_security_group" "secrets-efs-egress" {
  name        = "secrets-efs-egress"
  description = "SG For allowing traffic to EFS"
  vpc_id      = "${aws_vpc.get-players.id}"
  egress = [
    {
      security_groups = ["${aws_security_group.secrets-efs.id}"]
      cidr_blocks = []
      ipv6_cidr_blocks = []
      description = "Allow resources to mount EFS"
      protocol = "tcp"
      from_port = 2049
      to_port = 2049
      prefix_list_ids = ["${aws_vpc_endpoint.s3.prefix_list_id}"]
      self = false
    }
  ]
}

resource "aws_security_group" "s3-egress" {
  name        = "s3-egress"
  description = "SG For allowing traffic to S3"
  vpc_id      = "${aws_vpc.get-players.id}"
  egress = [{
      security_groups = ["${aws_security_group.secrets-efs.id}"]
      cidr_blocks = []
      ipv6_cidr_blocks = []
      description = "Allow resources to access S3"
      protocol = "tcp"
      from_port = 443
      to_port = 443
      prefix_list_ids = ["${aws_vpc_endpoint.s3.prefix_list_id}"]
      self = false
    }
  ]
}

resource "aws_security_group" "secrets-efs" {
  name        = "secrets-efs"
  description = "SG For allowing traffic to EFS"
  vpc_id      = "${aws_vpc.get-players.id}"
}

resource "aws_security_group_rule" "secrets-efs-ingress" {
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "tcp"
  security_group_id = "${aws_security_group.secrets-efs.id}"
  source_security_group_id = "${aws_security_group.secrets-efs-egress.id}"
}

resource "aws_datasync_location_efs" "secret-efs" {
  efs_file_system_arn = aws_efs_mount_target.secrets.file_system_arn

  ec2_config {
    security_group_arns = ["${aws_security_group.secrets-efs.arn}"]
    subnet_arn          = "${aws_subnet.player-data-lambdas.arn}"
  }
}

resource "aws_datasync_location_s3" "secret-s3" {
  s3_bucket_arn = "${aws_s3_bucket.secrets-efs.arn}"
  subdirectory  = "/secrets"

  s3_config {
    bucket_access_role_arn = "${aws_iam_role.syncEFSSecrets-datasync.arn}"
  }
}

resource "aws_datasync_task" "s3-efs-secrets" {
  destination_location_arn = "${aws_datasync_location_efs.secret-efs.arn}"
  name                     = "Sync secrets from S3 to EFS"
  source_location_arn      = "${aws_datasync_location_s3.secret-s3.arn}"

  options {
    preserve_deleted_files   = "REMOVE"
  }
}

resource "aws_lambda_function" "syncEFSSecrets" {
  function_name = "syncEFSSecrets"

  filename = "tmp/python_lambda.zip"

  runtime = "python3.9"
  handler = "main.lambda_handler"
  role    = "${aws_iam_role.syncEFSSecrets-lambda.arn}"
  timeout = 4

  vpc_config {
    subnet_ids         = ["${aws_subnet.player-data-lambdas.id}"]
    security_group_ids = ["${aws_security_group.secrets-efs-egress.id}"]
  }

  environment {
    variables = {
      S3SECRETBUCKETNAME = "${aws_s3_bucket.secrets-efs.bucket}"
    }
  }

  depends_on = [
    aws_efs_mount_target.secrets,
    aws_vpc_endpoint.s3
  ]
}

resource "aws_lambda_permission" "syncEFSSecrets" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.syncEFSSecrets.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.secrets-efs.arn}"
}

resource "aws_s3_bucket_notification" "efs-sync-notification" {
  bucket = "${aws_s3_bucket.secrets-efs.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.syncEFSSecrets.arn}"
    events              = [
                            "s3:ObjectCreated:*",
                            "s3:ObjectRemoved:*",
                            "s3:ObjectRestore:*"
                            ]
  }
}

resource "aws_iam_role" "syncEFSSecrets-datasync" {
  name = "syncEFSSecrets-datasync"
  assume_role_policy = data.aws_iam_policy_document.datasync-assume-role-policy.json
}

resource "aws_iam_role" "syncEFSSecrets-lambda" {
  name = "syncEFSSecrets-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "syncEFS-AWSLambdaVPCAccessExecutionRole" {
    role       = "${aws_iam_role.syncEFSSecrets-lambda.name}"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


resource "aws_iam_policy" "trigger-secret-datasync" {
  name        = "trigger-secret-datasync"
  description = "A policy that allows the resource to trigger datasync between S3 and EFS secret"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "datasync:DescribeTaskExecution",
        "datasync:DescribeTask",
        "datasync:StartTaskExecution"
      ],
      "Effect": "Allow",
      "Resource": "${aws_datasync_task.s3-efs-secrets.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "syncEFS-datasync" {
    role       = "${aws_iam_role.syncEFSSecrets-lambda.name}"
    policy_arn = "${aws_iam_policy.trigger-secret-datasync.arn}"
}

resource "aws_iam_policy" "syncEFSSecrets" {
  name        = "syncEFSSecrets"
  path        = "/"
  description = "syncEFSSecrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.secrets-efs.arn}"
      }
    ]
  })
}
