terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "lalit"
  region  = "ca-central-1"
}


resource "aws_instance" "web-talk2data" {
  ami                    = "ami-01c7ecac079939e18"
  instance_type          = "g5.8xlarge"
  key_name               = "key-ec2-talk2data-ssh"
  vpc_security_group_ids = [aws_security_group.main.id]

  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/update_sys.sh"
    destination = "/tmp/update_sys.sh"
  }

  user_data = file("userdata.sh")


  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/update_sys.sh",
      "sh /tmp/update_sys.sh"
    ]
  }

  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/nvidia_cuda_toolkit.sh"
    destination = "/tmp/nvidia_cuda_toolkit.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/nvidia_cuda_toolkit.sh",
      "sh /tmp/nvidia_cuda_toolkit.sh"
    ]
  }

  ###
  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/docker_install.sh"
    destination = "/tmp/docker_install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/docker_install.sh",
      "sh /tmp/docker_install.sh"
    ]
  }

  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/nvidia_tool_kit.sh"
    destination = "/tmp/nvidia_tool_kit.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/nvidia_tool_kit.sh",
      "sh /tmp/nvidia_tool_kit.sh"
    ]
  }

  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/update_fstab.sh"
    destination = "/tmp/update_fstab.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/update_fstab.sh",
      "sh /tmp/update_fstab.sh"
    ]
  }

  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/remount.sh"
    destination = "/tmp/remount.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/remount.sh",
      "sh /tmp/remount.sh"
    ]
  }

  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/ssl.sh"
    destination = "/tmp/ssl.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/ssl.sh",
      "sh /tmp/ssl.sh"
    ]
  }

  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/ebs-mount.sh"
    destination = "/tmp/ebs-mount.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/ebs-mount.sh",
      "sh /tmp/ebs-mount.sh"
    ]
  }

  provisioner "file" {
    source      = "/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/bbrowserx.sh"
    destination = "/tmp/bbrowserx.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bbrowserx.sh",
      "sh /tmp/bbrowserx.sh"
    ]
  }

  provisioner "remote-exec" {
    inline = ["sudo docker run -it -d -e WEB_DOMAIN=${var.domain} -e BIOTURING_TOKEN=${var.bioturing_token} -e SSO_DOMAINS=${var.sso_domain} -e ADMIN_USERNAME=${var.admin_user} -e ADMIN_PASSWORD=${var.admin_passwd} -v /data/user_data:/data/user_data -v /data/app_data:/data/app_data -v /config/ssl:/config/ssl --name bioturing-ecosystem --gpus all --shm-size=64gb -p 443:443 -p 80:80 bioturing/bioturing-ecosystem:2.0.1"]
  }

  ebs_block_device {
    delete_on_termination = true
    device_name           = "/dev/sdb"
    encrypted             = true
    volume_size           = 150
    volume_type           = "gp3"
  }

  tags = {
    Name = "talk2data"
  }
  root_block_device {
    volume_size = "100"
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/configuration_script/key-ec2-talk2data-ssh.pem")
    timeout     = "4m"
  }
}

resource "aws_security_group" "main" {
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 22
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 22
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 80
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    },
    {
      cidr_blocks      = ["0.0.0.0/0", ]
      description      = ""
      from_port        = 443
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 443
    }
  ]
}

resource "aws_key_pair" "talk2data" {
  key_name   = "key-ec2-talk2data-ssh"
  public_key = file("/home/ubuntu/teraform-code/bbrowserx-talk2data_new_version/key-ec2-talk2data-ssh.pub")
}
