
# This is used to create empty lambdas which can have their own deployment pipeline
data "archive_file" "python-lambda-null-zip" {
  type = "zip"
  output_path = "tmp/${path.module}/python_lambda.zip"

  source {
    filename = "main.py"
    content = "def lambda_handler(event, context):\n  return 'dank'"
  }
}
