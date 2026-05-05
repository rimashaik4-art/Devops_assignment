output "api_url" {
  value = "http://${aws_instance.api.public_ip}:8080"
}

output "frontend_url" {
  value = aws_s3_bucket.frontend.website_endpoint
}

output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}
