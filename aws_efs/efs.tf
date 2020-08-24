provider "aws" {
    region = "ap-south-1"
    profile = "myprofile"
}


resource "aws_security_group" "efsSecurityGroup" {
    name        = "efs-allow"
    description = "NFS access"
    vpc_id      = "vpc-91617df9"

    ingress {
        from_port   = 2049
        to_port     = 2049
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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
        Name = "efs_allow"
    }
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

resource "aws_instance" "web" {
    ami           = "ami-052c08d70def0ac62"
    instance_type = "t2.micro"
    key_name =  aws_key_pair.newKey.key_name
    security_groups = [ "${aws_security_group.efsSecurityGroup.name}" ]
    tags = {
        Name = "web-os"
    }
    depends_on = [
        aws_key_pair.newKey,
        aws_security_group.efsSecurityGroup
    ]
}

resource "aws_efs_file_system" "my_personal_efs" {
  creation_token = "my-efs"

  tags = {
    Name = "MyEFS"
  }
}

resource "aws_efs_mount_target" "efs-mount" {
   file_system_id  = "${aws_efs_file_system.my_personal_efs.id}"
   subnet_id = "${aws_instance.web.subnet_id}"
   security_groups = ["${aws_security_group.efsSecurityGroup.id}"]
 }