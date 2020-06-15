provider "aws" {

  profile = "sagar"
  region  = "us-east-2"
}

resource "aws_vpc" "terraform" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "terraform"

  }
}

resource "aws_internet_gateway" "gateway-terraform" {
  vpc_id = "${aws_vpc.terraform.id}"
  tags = {
    Name = "gw-terraform"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = "${aws_vpc.terraform.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }

}

resource "aws_subnet" "private-subnet" {
  vpc_id                  = "${aws_vpc.terraform.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-sunet"
  }
}


resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.terraform.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gateway-terraform.id}"
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "Nat-gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public-subnet.id}"
  tags = {
    Name = "Nat-gw"
  }

}


resource "aws_route_table" "private-rt" {
  vpc_id = "${aws_vpc.terraform.id}"
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.Nat-gw.id}"
  }
  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private-subnet.id}"
  route_table_id = "${aws_route_table.private-rt.id}"
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

resource "aws_key_pair" "terraform" {
  key_name   = "terraform"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBh1s4ZyZNlOpgLzWmZf4CzEv9pttEtzhRSx1RiVRHA/z+3nmFo2SFQThmLsuTewGvPWZO8c97qGopyiAx2tEW/TTP5ean0aStw1FrrJ0LLBg4/di9snzEkiLIRRyvXbYKpF4AIzrAqRybtaloC+4iEy2cKdgwXmlrp+ABQqic22ZndV7kYnTYEyf9Bs0cvCS6qEF12B+Kv4AbVrqSqVUm0q+T1MOBz3Ns/1qYsVMR6oETyx73AbvmyJByFRA58dlQ8BFS+eSiNB2NE4Guz6gEdWVdkXhG/MqbKJA6K7sLyi33gk5oy/6C6/4oRNfLmKY2BZmurmW1yOcCPwIfVacH rahul@rahul"

}


resource "aws_security_group" "allow_ports" {
  name        = "allow-ports"
  description = "security group"
  vpc_id      = "${aws_vpc.terraform.id}"

  ingress {
    description = "allow port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "allow ssh"
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
    Name = "terraform-grp"
  }
}

resource "aws_instance" "terraformPublic" {
  ami                    = "ami-07c1207a9d40bc3bd"
  instance_type          = "t2.micro"
  key_name               = "terraform"
  subnet_id              = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_ports.id}"]

  tags = {
    Name = "terrafromPrivate"
  }

  user_data = "${data.template_file.user_data.rendered}"

}
data "template_file" "user_data" {
  template = "${file("user_data.tpl")}"
}


