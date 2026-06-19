output "grafana_secret_arn" {
  value       = aws_secretsmanager_secret.grafana.arn
  description = "ARN of the Secrets Manager secret containing Grafana admin credentials"
}

output "otel_collector_endpoint_grpc" {
  value = "opentelemetry-collector.${var.namespace}.svc.cluster.local:4317"
}

output "otel_collector_endpoint_http" {
  value = "http://opentelemetry-collector.${var.namespace}.svc.cluster.local:4318"
}

output "grafana_url" {
  value = "http://kube-prometheus-stack-grafana.${var.namespace}.svc.cluster.local"
}
