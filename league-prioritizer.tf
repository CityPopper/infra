
resource "aws_sqs_queue" "player-user-requests" {
  name                        = "player-user-requests"
  tags                        = {}
}

resource "aws_sqs_queue" "player-discovery" {
  name                        = "player-discovery"
  tags                        = {}
}

resource "aws_sqs_queue" "player-refresh" {
  name                        = "player-refresh"
  tags                        = {}
}
