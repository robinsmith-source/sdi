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
  type    = list(string)
  default = []
  validation {
    condition     = length(distinct(var.server_aliases)) == length(var.server_aliases) && !contains(var.server_aliases, var.server_name)
    error_message = "Aliases must be unique and must not match the server_name."
  }
}
