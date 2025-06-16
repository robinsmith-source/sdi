variable "hcloud_token" {
  description = "Hetzner Cloud API token"
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
  description = "The canonical name of the server"
  type        = string
  nullable    = false
}

variable "server_ip" {
  description = "The IP address for the A records"
  type        = string
  nullable    = false
}

variable "server_aliases" {
  description = "List of server alias names"
  type        = list(string)
  nullable    = false

  validation {
    condition     = length(distinct(var.server_aliases)) == length(var.server_aliases)
    error_message = "Duplicate server alias names are not allowed."
  }

  validation {
    condition     = !contains(var.server_aliases, var.server_name)
    error_message = "Server alias names cannot match the server's canonical name."
  }
}
