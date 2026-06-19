grafana:
  adminPassword: "${grafana_password}"
  persistence:
    enabled: true
    size: 5Gi
  additionalDataSources:
    - name: Tempo
      type: tempo
      uid: tempo
      url: http://tempo.monitoring.svc.cluster.local:3100
      access: proxy
      jsonData:
        tracesToMetrics:
          datasourceUid: prometheus
          tags:
            - key: service.name
              value: service
        nodeGraph:
          enabled: true
        serviceMap:
          datasourceUid: prometheus
        lokiSearch:
          datasourceUid: ""

prometheus:
  prometheusSpec:
    retention: 15d
    enableRemoteWriteReceiver: true
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

alertmanager:
  config:
    global:
      resolve_timeout: 5m
    route:
      group_by: ["alertname", "namespace"]
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 12h
      receiver: "slack"
      routes:
        - matchers:
            - severity =~ "warning|critical"
          receiver: "slack"
    receivers:
      - name: "slack"
        slack_configs:
          - api_url: "${slack_webhook_url}"
            channel: "#alerts"
            title: '[{{ .Status | toUpper }}] {{ .CommonLabels.alertname }}'
            text: >-
              {{ range .Alerts }}
                *Alert:* {{ .Annotations.summary }}
                *Description:* {{ .Annotations.description }}
                *Namespace:* {{ .Labels.namespace }}
                *Severity:* {{ .Labels.severity }}
              {{ end }}
    inhibit_rules:
      - source_matchers:
          - severity = "critical"
        target_matchers:
          - severity = "warning"
        equal: ["alertname", "namespace"]
