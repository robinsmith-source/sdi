variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type = string
  nullable    = false
  sensitive   = true
}

variable "dns_secret" {
  description = "DNS HMAC-SHA512 key secret for DNS updates"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "dns_zone" {
  description = "The base domain for DNS records"
  type        = string
  nullable    = false
}

variable "server_name" {
  type    = string
}
