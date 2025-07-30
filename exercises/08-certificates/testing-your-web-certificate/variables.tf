variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
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

variable "server_names" {
  description = "List of subdomain names to create"
  type        = list(string)
  nullable    = false
  default     = []
}

variable "name_server" {
  description = "The DNS nameserver for ACME DNS challenges"
  type        = string
  nullable    = false
}

variable "email_address" {
  description = "Email address for Let's Encrypt registration"
  type        = string
  nullable    = false
}
