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

variable "name_server" {
  description = "The name server for DNS records"
  type        = string
  nullable    = false
}

variable "email_address" {
  description = "Email address for Let's Encrypt registration"
  type        = string
}
