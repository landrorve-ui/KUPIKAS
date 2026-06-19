output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_urls" {
  value = module.ecr.repository_urls
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "aurora_endpoint" {
  value = module.aurora.cluster_endpoint
}

output "aurora_reader_endpoint" {
  value = module.aurora.reader_endpoint
}

output "aurora_secret_arn" {
  value       = module.aurora.secret_arn
  description = "ARN of the Secrets Manager secret containing DATABASE_URL and credentials"
}

output "grafana_secret_arn" {
  value = module.monitoring.grafana_secret_arn
}

output "otel_collector_grpc" {
  value = module.monitoring.otel_collector_endpoint_grpc
}
