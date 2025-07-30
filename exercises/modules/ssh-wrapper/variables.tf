variable "login_user" {
  description = "The user to login to the server"
  type        = string
  nullable    = false
  default     = "root"
}

variable "public_key" {
  description = "The public key to use for the server"
  type        = string
  nullable    = false
}

variable "ipv4Address" {
  description = "The IPv4 address of the server"
  type        = string
  nullable    = true
  default     = null
}

variable "hostname" {
  description = "The hostname to connect to (alternative to ipv4Address)"
  type        = string
  nullable    = true
  default     = null
}