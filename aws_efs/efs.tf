// Configure provider
provider "aws" {
    region = "ap-south-1"
    profile = "myprofile"
}

// Create Security Group
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

// Generate Key
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


// Launch ec2 instance
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

// Create EFS filesystem
resource "aws_efs_file_system" "my_personal_efs" {
  creation_token = "my-efs"

  tags = {
    Name = "MyEFS"
  }
}

// Mount EFS filesystem to instance
resource "aws_efs_mount_target" "efs-mount" {
   depends_on = [
   	aws_efs_file_system.my_personal_efs,
   ]
   file_system_id  = "${aws_efs_file_system.my_personal_efs.id}"
   subnet_id = "${aws_instance.web.subnet_id}"
   security_groups = ["${aws_security_group.efsSecurityGroup.id}"]
 }
 
// Mount EFS filesystem to directory
resource "null_resource" "NFSConfig" {
    depends_on = [
    aws_efs_mount_target.efs-mount,
    aws_instance.web,
    ]
    connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = tls_private_key.keyGenerate.private_key_pem
        host     = aws_instance.webInstance.public_ip
    }

    provisioner "remote-exec" {
        inline = [
            "sudo yum install nfs-utils -y",
            "sudo mkdir /myfolder",
            "sudo mount -t nfs4 ${aws_efs_mount_target.EFSMount.dns_name}:/  /myfolder", 
        ]
    }
}

