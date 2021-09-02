resource "aws_s3_bucket" "getLeaguePlayer" {
  bucket = var.lambda_getleagueplayer_bucket
  acl    = "private"
  versioning {
    enabled = true
  }
  tags   = {
    Name = "getLeaguePlayer"
  }
}

resource "aws_s3_bucket_object" "getLeaguePlayer_lambda_src" {
    bucket = "${aws_s3_bucket.getLeaguePlayer.id}"
    acl    = "private"
    key    = "lambda.zip"
    source = "tmp/lambda.zip"
    lifecycle {
      ignore_changes = [
        key,
        tags,
        tags_all
      ]
    }
}

resource "aws_lambda_function" "getLeaguePlayer" {  
  function_name = "getLeaguePlayer"

  s3_bucket = aws_s3_bucket.getLeaguePlayer.bucket
  s3_key = aws_s3_bucket_object.getLeaguePlayer_lambda_src.key

  runtime = "python3.9"
  handler = "main.lambda_handler"
  role    = aws_iam_role.lambda-riot-league-api-key-reader.arn
}

resource "aws_sqs_queue" "player-update" {
  name                        = "player-update.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  tags                        = {}
}
