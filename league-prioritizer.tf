
resource "aws_sqs_queue" "player-user-requests" {
  name                        = "player-user-requests.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  tags                        = {}
}

resource "aws_sqs_queue" "player-discovery" {
  name                        = "player-discovery.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  tags                        = {}
}

resource "aws_sqs_queue" "player-refresh" {
  name                        = "player-refresh.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  tags                        = {}
}
