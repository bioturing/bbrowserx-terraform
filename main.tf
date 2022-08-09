provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

locals {
  // Get complete list of ip_ranges and split into multiple buckets if the number of ip_ranges exceeds the security group rule limit
  ssh_ip_ranges = length(var.ssh_ingress_ip_ranges) > 0 ? var.ssh_ingress_ip_ranges : ["0.0.0.0/0"]
  ssh_ip_ranges_chunks = chunklist(concat(local.ssh_ip_ranges, var.additional_ssh_ingress_ip_ranges), var.max_ingress_rules)
  ssh_ip_ranges_chunks_map = { for i in range(length(local.ssh_ip_ranges_chunks)): i => local.ssh_ip_ranges_chunks[i] }

  https_ip_ranges = length(var.https_ingress_ip_ranges) > 0 ? var.https_ingress_ip_ranges : ["0.0.0.0/0"]
  https_ip_ranges_chunks = chunklist(concat(local.https_ip_ranges, var.additional_https_ingress_ip_ranges), var.max_ingress_rules)
  https_ip_ranges_chunks_map = { for i in range(length(local.https_ip_ranges_chunks)): i => local.https_ip_ranges_chunks[i] }

  // Define common tags
  common_tags = {
    name = "Administrator"
    product = "bioturing-talk2data"
    project = var.project_name
    environment = var.environment
  }
  config_root = "/home/ubuntu/config"
}

resource "aws_security_group" "allow_ssh" {
  for_each = local.ssh_ip_ranges_chunks_map
  name = "allow_ssh-${var.project_name}-${each.key}"
  description = "Allow ssh traffic on port 22 from the specified IP addresses"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = each.value
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_https" {
  for_each = local.https_ip_ranges_chunks_map
  name = "allow_https-${var.project_name}-${each.key}"
  description = "Allow HTTPs traffic on port 22 from the specified IP addresses"

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = each.value
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami = var.ami == "" ? data.aws_ami.ubuntu.id : var.ami

  instance_type = var.instance_type

  tags = local.common_tags

  root_block_device {
    volume_type = var.root_block_device_type
    volume_size = var.root_block_device_size
  }

  key_name = var.key_name

  security_groups = concat(
    ["default"],
    [for allow_ssh_sg in aws_security_group.allow_ssh : allow_ssh_sg.name],
    [for allow_https_sg in aws_security_group.allow_https: allow_https_sg.name]
  )

  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  // We wait 300 seconds for the instance to complete boot before being ready
  provisioner "remote-exec" {
    inline = [
      "timeout 300 bash -c 'until [ -e /var/lib/cloud/instance/boot-finished ]; do sleep 5; done'",
    ]
  }
}

resource "aws_ebs_volume" "ebs_creation" {
  availability_zone = aws_instance.web.availability_zone
  final_snapshot = var.final_snapshot
  size = var.ebs_size
  type = var.ebs_type
  tags = {
    name = "storage-${var.project_name}"
    description = "Persistent storage for storing user data"
  }
}

# This is the trickiest part of aws terraform. A known issue from 2018 has not been resolved yet
# https://github.com/hashicorp/terraform-provider-aws/issues/4864
# If the instance already has ebs block, then ebs_block_device, aws_volume_attachment don't work properly.
# Currently the name of the EBS persistent storage is harcoded to nvme2n1 - for ubuntu aws g5 instance
resource "aws_volume_attachment" "ebs_attachment" {
  device_name = "/dev/sdh"
  volume_id = aws_ebs_volume.ebs_creation.id
  instance_id = aws_instance.web.id
}

resource "null_resource" "copy_config" {
  triggers = {
    instance_id = aws_instance.web.id
  }

  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "file" {
    source = "config"
    destination = local.config_root
  }

  provisioner "remote-exec" {
    inline = ["chmod +x ${local.config_root}/*.sh"]
  }
}

resource "null_resource" "initialize" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo ${local.config_root}/initialize.sh"]
  }

  depends_on = [
    null_resource.copy_config
  ]
}

resource "null_resource" "storage" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo ${local.config_root}/storage.sh"]
  }

  depends_on = [
    null_resource.initialize,
    aws_volume_attachment.ebs_attachment
  ]
}

resource "null_resource" "install_docker" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo ${local.config_root}/install_docker.sh"]
  }

  depends_on = [
    null_resource.storage
  ]
}

resource "null_resource" "install_nvidia_cuda_toolkit" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo ${local.config_root}/install_nvidia_cuda_toolkit.sh"]
  }

  depends_on = [
    null_resource.install_docker
  ]
}

resource "null_resource" "generate_configs" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo ${local.config_root}/generate_configs.sh ${var.port} ${var.domain} ${var.bioturing_token}"]
  }

  depends_on = [
    null_resource.install_nvidia_cuda_toolkit
  ]
}

resource "null_resource" "disable_auto_update" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo ${local.config_root}/disable_auto_update.sh"]
  }

  depends_on = [
    null_resource.generate_configs
  ]
}

resource "null_resource" "configure_nginx" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo ${local.config_root}/nginx.sh ${var.port} ${var.domain} ${var.htpasswd}"]
  }

  depends_on = [
    null_resource.disable_auto_update
  ]
}

resource "null_resource" "install_nvidia_container_toolkit" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo ${local.config_root}/install_nvidia_container_toolkit.sh"]
  }

  depends_on = [
    null_resource.configure_nginx
  ]
}

resource "null_resource" "pull_docker_image" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo docker pull bioturing/bbrowserx"]
  }

  depends_on = [
    null_resource.install_nvidia_container_toolkit
  ]
}

resource "null_resource" "start" {
  connection {
    host = aws_instance.web.public_ip
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key)
    agent = false
    timeout = var.ssh_timeout
  }

  provisioner "remote-exec" {
    inline = ["sudo docker run --shm-size=64gb --rm --gpus all --name talk2data -v /data:/data -p ${var.port}:${var.port} -d bioturing/bbrowserx"]
  }

  depends_on = [
    null_resource.pull_docker_image
  ]
}

output "instance_hostname" {
  value = "ubuntu@${aws_instance.web.public_dns}"
}

output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "private_key" {
  value = var.private_key
}
