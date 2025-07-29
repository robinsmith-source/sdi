variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "login_user" {
  description = "Login user for the server"
  type        = string
  nullable    = false
  default     = "devops"
}

variable "server_location" {
  description = "Location of the server"
  type        = string
  nullable    = false
  default     = "nbg1"
}