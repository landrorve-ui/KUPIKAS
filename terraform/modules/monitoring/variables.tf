variable "environment" {
  type = string
}

variable "namespace" {
  type    = string
  default = "monitoring"
}

variable "slack_webhook_url" {
  type      = string
  sensitive = true
  default   = "https://hooks.slack.com/services/REPLACE_ME"
}
