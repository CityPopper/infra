
resource "aws_iam_role_policy" "riot-league-api-key-reader" {
  name = "riot-league-api-key-reader"
  role = aws_iam_role.lambda-riot-league-api-key-reader.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.riot-league-api-key.arn
      },
    ]
  })
}

resource "aws_iam_role" "lambda-riot-league-api-key-reader" {
  name = "riot-league-api-key-reader"

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
