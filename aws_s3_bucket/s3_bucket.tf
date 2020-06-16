provider "aws" {
    region = "ap-south-1"
    profile = "myprofile"
}

resource "aws_s3_bucket" "webBucket" {
    bucket = "surin-bucket"
    acl = "private"
    force_destroy = true
    tags = {
        Name = "My bucket"
  }
}