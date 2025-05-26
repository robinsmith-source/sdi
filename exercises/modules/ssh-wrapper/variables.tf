variable "loginUser" {
  type = string
  default = "root"
}

variable "public_key" {
  type = string
  nullable = false
}

variable "ipv4Address" {
  type = string
  nullable = false
}
