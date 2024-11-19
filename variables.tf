variable "common_tags" {
  type = map(string)
  default = {
    "Name"             = "unifi-route53-ddns",
    "RootModuleSource" = "github/estubbs/unifi-route53-ddns"
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "authUser" {
  type      = string
  sensitive = true
}

variable "authPass" {
  type      = string
  sensitive = true
}
