provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0" # Example AMI for Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = var.key_name

  tags = {
    Name = "project-hub-server"
  }

  provisioner "local-exec" {
    command = <<-EOF
              ansible-playbook -i inventory.ini apache-setup.yml --private-key ${var.private_key_path}
              EOF
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}
