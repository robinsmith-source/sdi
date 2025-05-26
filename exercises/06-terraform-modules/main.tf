module "createHostAmongMetaData" {
  source       = "../modules/HostMetaData"
  name         = "myServer"
  hcloud_token = var.hcloud_token
}
