terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
    }

  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "dns" {
  update {
    server        = "ns1.sdi.hdm-stuttgart.cloud"
    key_name      = "g10.key."
    key_algorithm = "hmac-sha512"
    key_secret    = var.dns_secret
  }
}
