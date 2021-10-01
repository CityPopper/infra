resource "aws_vpc" "get-players" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    instance_tenancy = "default"
    tags = {
      "Name" = "get-players"
    }
}


resource "aws_default_security_group" "get-players" {
  vpc_id = "${aws_vpc.get-players.id}"
}
resource "aws_internet_gateway" "get-players" {
  vpc_id = "${aws_vpc.get-players.id}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.get-players.id}"
  service_name = "com.amazonaws.us-east-1.s3"
  route_table_ids = ["${aws_vpc.get-players.main_route_table_id}"]
}
