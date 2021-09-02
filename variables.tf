variable "region" {
  type = string
  default = "us-east-1"
}

variable "lambda_getleagueplayer_bucket" {
  type = string
  description = "Bucket to store lambda code"
}
