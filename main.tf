# Create s3 bucket
resource "aws_s3_bucket" "goodnessbucket" {
  bucket = var.bucketname
  tags = {
    Name        = "Goodness bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.goodnessbucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.goodnessbucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [
    aws_s3_bucket_ownership_controls.example,
    aws_s3_bucket_public_access_block.example,
  ]

  bucket = aws_s3_bucket.goodnessbucket.id
  acl    = "public-read"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.goodnessbucket.id
  key          = "index.html"
  source       = "index.html"
  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.goodnessbucket.id
  key          = "error.html"
  source       = "error.html"
  acl          = "public-read"
  content_type = "text/html"
}

resource "aws_s3_object" "profile" {
  bucket       = aws_s3_bucket.goodnessbucket.id
  key          = "profile.jpeg"
  source       = "profile.jpeg"
  acl          = "public-read"
  content_type = "image/jpeg"
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.goodnessbucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  depends_on = [aws_s3_bucket_acl.example]
}

# ✅ Add this to allow public access to all objects in the bucket
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.goodnessbucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action = [
          "s3:GetObject"
        ],
        Resource = "${aws_s3_bucket.goodnessbucket.arn}/*"
      }
    ]
  })
}



# 3. Create CloudFront Distribution using custom origin config (website endpoint)
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.goodnessbucket.id}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.goodnessbucket.id}"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "Goodness CDN"
    Environment = "Dev"
  }

  depends_on = [aws_s3_bucket_website_configuration.website]
}

# Note: This version uses the S3 static website hosting endpoint and does NOT require Origin Access Control (OAC).
# The bucket will need to be publicly accessible. Make sure to set an S3 bucket policy for public read access if needed.

