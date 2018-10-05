resource "aws_vpc" "webapp-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags {
        Name = "terraform-webapp-vpc"
    }
}

resource "aws_internet_gateway" "webapp-igw" {
    vpc_id = "${aws_vpc.webapp-vpc.id}"
}

resource "aws_subnet" "public-subnet-az1" {
    vpc_id = "${aws_vpc.webapp-vpc.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
    tags {
        Name = "Public subnet AZ1"
    }
}

resource "aws_subnet" "public-subnet-az2" {
    vpc_id = "${aws_vpc.webapp-vpc.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-east-1b"
    tags {
        Name = "Public subnet AZ2"
    }
}

resource "aws_route_table" "vpc-public-rt" {
    vpc_id = "${aws_vpc.webapp-vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.webapp-igw.id}"
    }

    tags {
        Name = "Public subnets route table"
    }
}

resource "aws_route_table_association" "public-subnet1-rt" {
    subnet_id = "${aws_subnet.public-subnet-az1.id}"
    route_table_id = "${aws_route_table.vpc-public-rt.id}"
}

resource "aws_route_table_association" "public-subnet2-rt" {
    subnet_id = "${aws_subnet.public-subnet-az2.id}"
    route_table_id = "${aws_route_table.vpc-public-rt.id}"
}
