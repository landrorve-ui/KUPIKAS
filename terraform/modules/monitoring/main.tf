resource "random_password" "grafana" {
  length           = 24
  special          = false
}

resource "aws_secretsmanager_secret" "grafana" {
  name                    = "zupikas/${var.environment}/grafana"
  description             = "Grafana admin credentials"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "grafana" {
  secret_id     = aws_secretsmanager_secret.grafana.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana.result
  })
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = var.namespace
  create_namespace = true
  version          = "65.1.0"
  timeout          = 600

  values = [
    templatefile("${path.module}/values/kube-prometheus-stack.yaml.tpl", {
      grafana_password  = random_password.grafana.result
      slack_webhook_url = var.slack_webhook_url
    })
  ]
}

resource "helm_release" "tempo" {
  name       = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "tempo"
  namespace  = var.namespace
  version    = "1.10.1"

  values = [file("${path.module}/values/tempo.yaml")]

  depends_on = [helm_release.kube_prometheus_stack]
}

resource "helm_release" "otel_collector" {
  name       = "opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  namespace  = var.namespace
  version    = "0.108.0"

  values = [file("${path.module}/values/otel-collector.yaml")]

  depends_on = [helm_release.tempo]
}
