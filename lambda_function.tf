data "archive_file" "lambda" {
  type             = "zip"
  source_file      = "./nodesrc/index.mjs"
  output_path      = "lambda_unifi_route53_ddns_function_payload.zip"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "unifi_route53_ddns" {
  architectures = ["arm64"]

  filename      = "lambda_unifi_route53_ddns_function_payload.zip"
  function_name = "unifi_route53_ddns"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "nodejs20.x"

  environment {
    variables = {
      authUser = var.authUser
      authPass = var.authPass
    }
  }
}
