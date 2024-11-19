variable "common_tags" {
  type = map(string)
  default = {
    "Name"               = "unifi-route53-ddns",
    "RootModuleSource"   = "https://github.com/estubbs/unifi-route53-ddns.git"
    "DeploymentType"     = "terraform"
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
  description = "The region to deploy your lambda to which will listen to requests from your dynamic dns client"
}

variable "authUser" {
  type      = string
  sensitive = true
  description = "A username of your choosing, will be used by the lambda to authenticate your dymamic dns client"
}

variable "authPass" {
  type      = string
  sensitive = true
  description = "A password of your choosing, will be used by the lambda to authenticate your dynamic dns client"
}

variable "hostedZoneId" {
  type = string
  description = "This is the ID of your hosted zone in route53 that cotains the record you want to update.  It MUST be in the form of `XXXXXXXX` NOT in the form of `/hostedzone/XXXXXXXXXX`. You can find this in the aws console, or by calling `aws route53 list-hosted-zones`"
}
