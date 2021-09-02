
# This is used to create empty lambdas which can have their own deployment pipeline
data "archive_file" "lambda_null_zip" {
  type = "zip"
  output_path = "tmp/${path.module}/lambda.zip"

  source {
    filename = "null"
    content = "null"
  }
}
