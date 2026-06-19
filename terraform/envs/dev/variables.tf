variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for Alertmanager notifications"
  type        = string
  sensitive   = true
  default     = "https://hooks.slack.com/services/REPLACE_ME"
}
