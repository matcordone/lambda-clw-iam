# Bucket for storing files
module "s3_bucket_old" {
    source  = "terraform-aws-modules/s3-bucket/aws"
    version = "5.12.0"
    bucket = var.bucket_name_old
}
module "s3_bucket_new" {
    source  = "terraform-aws-modules/s3-bucket/aws"
    version = "5.12.0"
    bucket = var.bucket_name_new
}

# S3 trigger notification
resource "aws_s3_bucket_notification" "trigger" {
  bucket = module.s3_bucket_old.s3_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda_function.lambda_function_arn
    events              = ["s3:ObjectCreated:Put"]
  }

  depends_on = [module.lambda_function]
}

# Lambda function configuration
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.7.0"

  function_name = "lambda_clw_iam"
  description   = "My awesome lambda function"
  handler       = "main.lambda_handler"
  runtime       = "python3.14"
  

  environment_variables = {
    "NEW_BUCKET_NAME" = var.bucket_name_new
    "NEW_KEY" = var.new_key
    }

  create_role = false
  lambda_role = aws_iam_role.lambda_role.arn
  source_path = "/src/main.py"


  # s3 trigger configuration
  create_current_version_allowed_triggers = false
  allowed_triggers = {
    s3 = {
      service    = "s3"
      source_arn = module.s3_bucket_old.s3_bucket_arn
    }
  }

  depends_on = [ aws_iam_role_policy.lambda_policy ]

  tags = {
    Name = "lambda_clw_iam"
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda-clw-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# IAM policy for Lambda function to access S3 buckets and CloudWatch Logs
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-clw-iam-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${module.s3_bucket_old.s3_bucket_arn}/*",
          "${module.s3_bucket_new.s3_bucket_arn}/*"
        ]
      },
      {
        Sid = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-1:373421021806:log-group:/aws/lambda/lambda_clw_iam:*:*",
          "arn:aws:logs:us-east-1:373421021806:log-group:/aws/lambda/lambda_clw_iam:*"
        ]
      }
    ]
  })
}
