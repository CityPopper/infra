terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"

  backend "s3" {
    bucket = ""
    key    = "state"
    region = "us-east-1"
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"

  default_tags {
    tags = { terraform : "true" }
  }
}

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

resource "aws_sqs_queue" "player-update" {
  name                        = "player-update.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  tags                        = {}
}

resource "aws_secretsmanager_secret" "riot-league-api-key" {
  name = "riot-league-api-key"
}
