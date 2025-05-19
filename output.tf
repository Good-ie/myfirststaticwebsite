output "websiteendpoint" {
  value = "http://${aws_s3_bucket.goodnessbucket.bucket}.s3-website.${var.region}.amazonaws.com"
}
output "cloudfront_url" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "CloudFront Distribution Domain"
}
