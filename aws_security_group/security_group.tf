provider "aws" {
    region = "ap-south-1"
    profile = "myprofile"
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