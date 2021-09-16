resource "aws_subnet" "player-data-lambdas" {
  vpc_id     = aws_vpc.get-players.id
  cidr_block = "10.0.0.0/20"

  tags = {
    Name = "lambdas"
  }
}
