variable "domain" {
  type        = string
  description = "A domain name for users to access the private Talk2Data platform through web interface."
}

variable "bioturing_token" {
  type        = string
  description = "A token provided by BioTuring for authenticating API calls to BioTuring server."
}

variable "sso_domain" {
  type        = string
  description = "SSO domain to auth login."
}

variable "admin_user" {
  type        = string
  description = "Admin user name, who is going to manage -- management console."
}

variable "admin_passwd" {
  type        = string
  description = "Admin Passwd for admin user."
}



