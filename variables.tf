variable "region" {
  type = string
}

variable "lambda_getleagueplayer_bucket" {
  type = string
  description = "Bucket to store lambda code"
}

variable "efs_secrets" {
  type = string
  description = "Efs to store secrets"
}
