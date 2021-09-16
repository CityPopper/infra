resource "aws_lambda_function" "getLeaguePlayer" {  
  function_name = "getLeaguePlayer"

  filename = "tmp/python_lambda.zip"

  runtime = "python3.9"
  handler = "main.lambda_handler"
  role    = aws_iam_role.lambda.arn
  timeout = 5

  file_system_config {
    arn = aws_efs_access_point.riot-api-key.arn
    local_mount_path = "/mnt/secrets"
  }

  vpc_config {
    subnet_ids         = [aws_subnet.player-data-lambdas.id]
    security_group_ids = [
                           aws_security_group.secrets-efs-egress.id,
                           aws_security_group.getLeaguePlayer.id
                         ]
  }

  depends_on = [
    aws_efs_mount_target.secrets
  ]
}

resource "aws_security_group" "getLeaguePlayer" {
  name        = "getLeaguePlayer"
  description = "SG for getLeaguePlayer"
  vpc_id      = aws_vpc.get-players.id

  egress = [
    {
      security_groups = null
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      description =  "HTTPS"
      protocol = "tcp"
      from_port = 443
      to_port = 443
      prefix_list_ids = null
      self = null
    }
  ]
}

resource "aws_sqs_queue" "player-update" {
  name                        = "player-update"
  tags                        = {}
}
