terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.0"
    }
    dns = {
      source  = "providers.tf-dns.com/com/dns"
      version = "~> 3.0"
    }
    acme = {
      source = "vancluever/acme"
    }
    tls = {
      source = "hashicorp/tls"
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

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}
