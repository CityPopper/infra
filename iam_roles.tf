resource "aws_iam_role_policy_attachment" "lambda" {
  role = aws_iam_role.lambda.id
  policy_arn = "${data.aws_iam_policy.AWSLambdaVPCAccessExecutionRole.arn}"
}

data "aws_iam_policy" "AWSLambdaVPCAccessExecutionRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role" "lambda" {
  name = "lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    sid    = ""
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "datasync-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect = "Allow"
    sid    = ""
    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}
