resource "aws_vpc" "myVpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  tags = {
    Name = "myVpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myVpc.id

  tags = {
    Name = "igw"
  }
}

resource "aws_subnet" "mySubnet" {
  vpc_id     = aws_vpc.myVpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "mySubnet"
  }
}

resource "aws_route_table" "myRT" {
  vpc_id = aws_vpc.myVpc.id

  route = []

  tags = {
    Name = "myRouteTable"
  }
}
resource "aws_route" "myR" {
  route_table_id            = aws_route_table.myRT.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id  = aws_internet_gateway.igw.id
  depends_on                = [aws_route_table.myRT]
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mySubnet.id
  route_table_id = aws_route_table.myRT.id
}

#Generate a key
resource "tls_private_key" "keyGenerate" {
    algorithm = "RSA"
}

# create key-pairs
resource "aws_key_pair" "key-pairs" {
depends_on = [
	tls_private_key.keyGenerate
    ]
  key_name   = "tf-key"
  public_key = tls_private_key.keyGenerate.public_key_openssh
}

# saving key in local system
resource "local_file" "keySave" {
    depends_on = [
	tls_private_key.keyGenerate
    ]
    content = tls_private_key.keyGenerate.private_key_pem
    filename = "tf-key.pem"
}

# create security-groups
resource "aws_security_group" "webserver" {
  name = "allow_all"
  description = "Allow all inbound traffic"

  ingress {
      from_port = 0
      to_port = 65535
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webserver_sg"
  }
}

# launch ec2 instance and configure apache-webserver
resource "aws_instance" "tf_instance" {
depends_on = [
    aws_security_group.webserver,aws_key_pair.key-pairs
  ]
  ami           = "ami-087c17d1fe0178315"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key-pairs.key_name
  vpc_security_group_ids = ["${aws_security_group.webserver.id}"]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.keyGenerate.private_key_pem
    host     = aws_instance.tf_instance.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Building a SSH connection...' ",

    ]
  }

  tags = {
    Name = "FoodVybe"
  }

provisioner "local-exec" {
  command = "echo ${aws_instance.tf_instance.public_ip} >> ip"
  }

  provisioner "local-exec" {
        command = "chmod 400 tf-key.pem"
  }

provisioner "local-exec" {
command = "ansible-playbook -i ${aws_instance.tf_instance.public_ip}, --private-key tf-key.pem setup.yml"
  }

}

# create EBS volume
resource "aws_ebs_volume" "tf_ebs_vol" {
depends_on = [
    aws_instance.tf_instance,
  ]
  availability_zone = aws_instance.tf_instance.availability_zone
  size              = 8
  tags = {
    Name = "tf_ebs_vol_8gb"
  }
}

# mount EBS volume to ec2 instance
resource "aws_volume_attachment" "tf_ebs_attach" {
depends_on = [
    aws_ebs_volume.tf_ebs_vol,
  ]
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.tf_ebs_vol.id
  instance_id = aws_instance.tf_instance.id
  force_detach = true
}

# ebs volume link
resource "null_resource" "mount-web-file"  {
depends_on = [
    aws_volume_attachment.tf_ebs_attach,
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.keyGenerate.private_key_pem
    host     = aws_instance.tf_instance.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var"
    ]
  }
}

output "Applicaiton-IP" {
    value = aws_instance.tf_instance.public_ip
}
