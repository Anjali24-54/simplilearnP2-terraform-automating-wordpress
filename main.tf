# Local values - to be used during resource creation

locals {

  ami_id = "ami-080e1f13689e07408"

  vpc_id = "vpc-0c4a7452df9e5039d" # your vpc-id

  ssh_user = "ubuntu"

  key_name = "Demokey"

  private_key_path = "/home/labsuser/simplilearnP2-terraform-automating-wordpress/Demokey.pem" # path to your saved private key

}



# Provider section

provider "aws" {

  access_key = "ASIAZVGAGDZCIMMBSYVV" # your access_key

  secret_key = "2k/IPAtaXX6E3XKNzCMKo14M9/gk76FajjHfl474" # your secret_key

  token = "FwoGZXIvYXdzEJT//////////wEaDBhmD5uTiJZ6qtLKxiK1AYu4g7DUgAfXp8DiEd454wSc44mQa2hsFzkImlP4InHGXQwZzAdXDQzTH085hoPebjEosvcVI5ue2s9ATUGiguJgLrZiby4xvL81UvUcMkxPX6rNPQO98DIb4H6O7ktszzs+5xtp864YnYRATKLhy53pyduhz2GE5WzQPaeboJbc7vf4oV3+vyREYgY/bprcNQUPm7d31jK0MPqeeao6572XFXZoi+br9QSbGjP4rRugpHfI4iIop/LpsQYyLc8TsJ0e2GC6yeevMaRoFsxGKV5ve+xDI4DDf+4Jwplb8B/Pyml4RRhlTHnp4Q==" #your token-key

  region = "us-east-1"

}



# AWS security group resource block - 2 inbound & 1 outbound rule added

resource "aws_security_group" "demoaccess" {

  name = "demoaccess"

  vpc_id = local.vpc_id



  ingress {

    from_port = 22

    to_port = 22

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }



  ingress {

    from_port = 80

    to_port = 80

    protocol = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }



  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}



# AWS EC2 instance resource block

resource "aws_instance" "web" {

  ami = local.ami_id

  instance_type = "t2.micro"

  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.demoaccess.id]

  key_name = local.key_name



  tags = {

    Name = "Demo Test"

  }



  # SSH Connection block which will be used by the provisioners - remote-exec

  connection {

    type = "ssh"

    host = self.public_ip

    user = local.ssh_user

    private_key = file(local.private_key_path)

    timeout = "4m"

  }



  # Remote-exec Provisioner Block - wait for SSH connection

  provisioner "remote-exec" {

    inline = [

      "echo 'wait for SSH connection to be ready...'",

      "touch /home/ubuntu/demo-file-from-terraform.txt"

    ]

  }



  # Local-exec Provisioner Block - create an Ansible Dynamic Inventory

  provisioner "local-exec" {

    command = "echo ${self.public_ip} > myhosts"

  }



  # Local-exec Provisioner Block - execute an ansible playbook

  provisioner "local-exec" {

    command = "ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} --vault-password-file pass-file wordpress11.yaml && ansible-playbook -i myhosts --user ${local.ssh_user} --private-key ${local.private_key_path} demoplaybook.yml"

  }

}



# Output block to print the public ip of instance

output "instance_ip" {

  value = aws_instance.web.public_ip
}
