provider "aws" {
  profile                 = "default"
  shared_credentials_file = "~/.aws/credentials"
  region                  = "ap-south-1"
}


resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
resource "aws_subnet" "main" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "ap-south-1a"
}
resource "aws_internet_gateway" "prod-igw" {
    vpc_id = aws_vpc.main.id
}
resource "aws_route_table" "prod-public-crt" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0"
        //CRT uses this IGW to reach internet
        gateway_id = "${aws_internet_gateway.prod-igw.id}"
    }

}
resource "aws_route_table_association" "prod-crta-public-subnet-1"{
    subnet_id = "${aws_subnet.main.id}"
    route_table_id = "${aws_route_table.prod-public-crt.id}"
}
resource "aws_key_pair" "keypair" {
  key_name   = "key"
  public_key = file("../key/kris.pub")
  #public_key = file("../key/aws-ubuntu.pem")
}
resource "aws_security_group" "ssh-allowed" {
    vpc_id = "${aws_vpc.main.id}"

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // This means, all ip address are allowed to ssh !
        // Do not do it in the production.
        // Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }
    //If you do not add this rule, you can not reach the NGIX
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# resource "aws_instance" "web" {
#   ami           = "ami-04505e74c0741db8d"
#   instance_type = "t2.micro"
#   subnet_id = "${aws_subnet.main.id}"
#   key_name       = aws_key_pair.keypair.key_name
#   vpc_security_group_ids = ["${aws_security_group.ssh-allowed.id}"]

#   tags = {
#     Name = "HelloWorld"
#   }
# }