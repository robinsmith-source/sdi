variable "loginUser" {
  type    = string
  default = "root"
}

variable "public_key" {
  type     = string
  nullable = false
}

variable "ipv4Address" {
  type     = string
  nullable = true
  default  = null
}

variable "hostname" {
  description = "The hostname to connect to (alternative to ipv4Address)"
  type        = string
  nullable    = true
  default     = null
}
