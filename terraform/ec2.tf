locals {
    instance_type = "t2.micro" 
    ami = "ami-0e001c9271cf7f3b9" #(Ubuntu 20.04)
    key_pem_name = "traefik_example" 
    security_groups = ["sg-XXXXXXXXXXX"] 
    subnet_id = "subnet-XXXXXXXXXX" 
    allocation_id = "eipalloc-XXXXXXXXXXXXXX"
    pem_route = "~/git/pems/traefik_example.pem" 
}

provider "aws" {
    region     = "us-east-1"
    access_key = "XXXXXXXXXXXXXXXXXXX"
    secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}

resource "aws_instance" "Docker-Services" {
    ami = local.ami
    instance_type = local.instance_type
    key_name = local.key_pem_name
    security_groups = local.security_groups
    subnet_id = local.subnet_id
    associate_public_ip_address = true
    tags = {
        Name = "Docker-Service"
    }

}

resource "aws_eip_association" "eip_assoc" {
    instance_id   = aws_instance.Docker-Services.id
    allocation_id = local.allocation_id
    depends_on = [ aws_instance.Docker-Services ]
}

resource "null_resource" "post_setup" {
    
    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = file(local.pem_route)
        host        = aws_eip_association.eip_assoc.public_ip
    }

    provisioner "file" {
        source      = "install.sh"
        destination = "/tmp/install.sh"
    }

    provisioner "file" {
        source      = "/Users/brian/git/trefik/certificado/docker-compose.yml"
        destination = "/home/ubuntu/docker-compose.yml"
    }

    provisioner "file" {
        source      = "/Users/brian/git/trefik/app/app.yml"
        destination = "/home/ubuntu/app.yml"
    }

    provisioner "remote-exec" {
        inline = [
            "sudo chmod +x /tmp/install.sh",
            "sudo bash /tmp/install.sh"
        ]
    }

    depends_on = [aws_eip_association.eip_assoc]
}
