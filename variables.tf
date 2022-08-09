variable "key_name" {
  type = string
  description = "The name of the AWS key to use for the created instance(s)"
}

variable "private_key" {
  type = string
  description = "The private key associated with the instance key"
}

variable "bioturing_token" {
  type = string
  description = "A token provided by BioTuring for authenticating API calls to BioTuring server"
}

variable "domain" {
  type = string
  description = "A domain name for users to access the private Talk2Data platform through web interface"
}

variable "environment" {
  type = string
  description = "Can be development or production"
  default = "production"
}

variable "port" {
  type = number
  description = "A number from range 1024 - 65535 to specify the port where the private Talk2Data process is running on"
  default = 3000
}

variable "htpasswd" {
  type = string
  description = "A string contains username and encrypted password for nginx authentication. Can be generated using the command htpasswd -n username"
  default = "admin:$apr1$c4jacuLY$ulHszg0B7fcO0uz4CFn2F/"
}

variable "region" {
  type = string
  default = "us-west-2"
}

variable "project_name" {
  type = string
  default = "bbrowserx"
}

variable "instance_type" {
  type = string
  description = "AWS EC2 GPU instance type"
  default = "g5.8xlarge"
}

variable "root_block_device_type" {
  type = string
  description = "The root block device type of the instance. Can be standard, gp2, gp3, io1, io2, sc1 or st1"
  default = "gp2"
}

variable "root_block_device_size" {
  type = number
  description = "The root block device size of the instance in GiBs"
  default = 128
}

variable "max_ingress_rules" {
  type = number
  description = "The maximum number of ingress rules per security group"
  default = 60
}

variable "ssh_ingress_ip_ranges" {
  type = list(string)
  description = "The CIDR blocks to allow SSH access from"
  default = []
}

variable "https_ingress_ip_ranges" {
  type = list(string)
  description = "The CIDR blocks to allow HTTPs traffic from the internet"
  default = []
}

variable "additional_ssh_ingress_ip_ranges" {
  type = list(string)
  description = "CIDR blocks to always append to the ssh ingress CIDR list"
  default = []
}

variable "additional_https_ingress_ip_ranges" {
  type = list(string)
  description = "CIDR blocks to always append to the https ingress CIDR list"
  default = []
}

variable "ebs_size" {
  type = number
  description = "The size of the EBS volume in GiBs"
  default = 1024
}

variable "ebs_type" {
  type = string
  description = "The type of EBS volume. Can be standard, gp2, gp3, io1, io2, sc1 or st1"
  default = "gp2"
}

variable "final_snapshot" {
  type = bool
  description = "If true, snapshot will be created before volume deletion. Any tags on the volume will be migrated to the snapshot. By default set to false"
  default = false
}

variable "ami" {
  type = string
  default = ""
}

variable "ssh_timeout" {
  type = string
  description = "The timeout to wait for the connection to become available. Should be provided as a string (e.g., \"30s\" or \"5m\")"
  default = "5m"
}
