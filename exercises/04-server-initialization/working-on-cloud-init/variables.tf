variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "login_user" {
  description = "Login user for the server"
  nullable    = false
  default     = "devops"
}

