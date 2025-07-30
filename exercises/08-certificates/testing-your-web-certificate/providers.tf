terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
    }
    acme = {
      source = "vancluever/acme"
    }
    tls = {
      source = "hashicorp/tls"
    }
    dns = {
      source = "hashicorp/dns"
    }
  }
  required_version = ">= 0.13"
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

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
