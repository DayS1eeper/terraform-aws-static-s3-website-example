terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "bucket_name" {
  type = string
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

resource "aws_s3_bucket_object" "website" {
  for_each = fileset(path.root, "*.html")

  bucket       = aws_s3_bucket.website.bucket
  key          = each.value
  source       = "${path.root}/${each.value}"
  etag         = filemd5("${path.root}/${each.value}")
  content_type = "text/html"
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.allow_public_read.json
}

resource "aws_s3_bucket_website_configuration" "static_website" {
  bucket = aws_s3_bucket.website.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "not_found.html"
  }
}

data "aws_iam_policy_document" "allow_public_read" {
  statement {
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.bucket_name}"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

output "website" {
  value     = "http://${var.bucket_name}.s3-website.${aws_s3_bucket.website.region}.amazonaws.com/"
  sensitive = false
}
