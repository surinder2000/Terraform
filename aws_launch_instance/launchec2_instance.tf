provider "aws" {
    region = "ap-south-1"
    profile = "myprofile"
}

resource "tls_private_key" "keyGenerate" {
    algorithm = "RSA"
}

resource "aws_key_pair" "newKey" {
    key_name   = "mykey2"
    public_key = tls_private_key.keyGenerate.public_key_openssh
}

resource "local_file" "keySave" {
    content = tls_private_key.keyGenerate.private_key_pem
    filename = "mykey2.pem"
}


resource "aws_security_group" "webServerFirewall" {
    name        = "webFirewall"
    description = "SSH and HTTP access"
    vpc_id      = "vpc-91617df9"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "webFirewall"
    }
}


resource "aws_instance" "web" {
    ami           = "ami-052c08d70def0ac62"
    instance_type = "t2.micro"
    key_name =  aws_key_pair.newKey.key_name
    security_groups = [ "${aws_security_group.webServerFirewall.name}" ]
    tags = {
        Name = "web-os"
    }
    depends_on = [
        aws_key_pair.newKey,
        aws_security_group.webServerFirewall
    ]
}