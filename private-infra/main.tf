# Generate a private key for SSH access
resource "tls_private_key" "example" {
  provider = aws.region_1
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "example" {
  provider = aws.region_1
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "private_key" {
  provider = aws.region_1
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
}

# VPC
resource "aws_vpc" "k3s-vpc-1" {
  provider = aws.region_1
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "k3s-vpc-1"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "k3s-igw" {
  provider = aws.region_1
  vpc_id = aws_vpc.k3s-vpc.id

  tags = {
    Name = "k3s-igw"
  }
}

# Create EIP for NAT Gateway
resource "aws_eip" "net-eip" {
provider = aws.region_1
  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "k3s-nat" {
  provider = aws.region_1
  allocation_id = aws_eip.net-eip.id
  subnet_id     = aws_subnet.k3s-public.id

  tags = {
    Name = "k3s-nat"
  }
}

# Create EIP for NAT Gateway
resource "aws_eip" "net-eip1" {
  provider = aws.region_1
  tags = {
    Name = "nat-eip1"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "k3s-nat1" {
  provider = aws.region_1
  allocation_id = aws_eip.net-eip1.id
  subnet_id     = aws_subnet.k3s-public.id

  tags = {
    Name = "k3s-nat"
  }
}

# Public Subnet for Bastion Host
resource "aws_subnet" "k3s-public" {
  provider = aws.region_1
  vpc_id            = aws_vpc.k3s-vpc.id
  cidr_block        = var.public_subnet_a_cidr_block
  availability_zone = var.zone1

  tags = {
    Name = "k3s-public"
  }
}

# Private Subnet for Private EC2 Instance
resource "aws_subnet" "k3s-private" {
  provider = aws.region_1
  vpc_id            = aws_vpc.k3s-vpc.id
  cidr_block        = var.private_subnet_b_cidr_block
  availability_zone = var.zone1

  tags = {
    Name = "k3s-private"
  }
}

# Public Route Table
resource "aws_route_table" "k3s-rt-public" {
  provider = aws.region_1
  vpc_id = aws_vpc.k3s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s-igw.id
  }

     route {
    cidr_block     = "0.0.0.0/16"
    nat_gateway_id = aws_nat_gateway.k3s-nat1.id
  }
  

  tags = {
    Name = "pub-route-table"
  }
}

# Private Route Table (using NAT Gateway)
resource "aws_route_table" "k3s-rt-private" {
  provider = aws.region_1
  vpc_id = aws_vpc.k3s-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.k3s-nat.id
  }

  tags = {
    Name = "pvt-route-table"
  }
}

# Associate Route Tables with Subnets
resource "aws_route_table_association" "a" {
  provider = aws.region_1
  subnet_id      = aws_subnet.k3s-public.id
  route_table_id = aws_route_table.k3s-rt-public.id
}

resource "aws_route_table_association" "b" {
  provider = aws.region_1
  subnet_id      = aws_subnet.k3s-private.id
  route_table_id = aws_route_table.k3s-rt-private.id
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  provider = aws.region_1
  name        = "bastion-sg"
  description = "Allow SSH access to the bastion host"
  vpc_id      = aws_vpc.k3s-vpc.id

ingress {
    description = "HTTP PORT"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Load Balancer to K3s"
    from_port   = var.k3s_service_port
    to_port     = var.k3s_service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s API server"
    from_port   = var.k3s_api_port
    to_port     = var.k3s_api_port
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
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "private_sg" {
  provider = aws.region_1
  name        = "private-sg"
  description = "Allow SSH access from bastion"
  vpc_id      = aws_vpc.k3s-vpc.id

 ingress {
    description = "HTTP PORT"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Load Balancer to K3s"
    from_port   = var.k3s_service_port
    to_port     = var.k3s_service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s API server"
    from_port   = var.k3s_api_port
    to_port     = var.k3s_api_port
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
    Name = var.sg_name
  }
}

resource "aws_eip" "nlb_eip" {
  count = 1
tags = {
    Name = "nlb-eip"
  }
}


resource "aws_lb" "my_nlb" {
  provider = aws.region_1
  name                    = var.lb_name
  internal                = false
  load_balancer_type      = "network"
  enable_deletion_protection = false

  dynamic "subnet_mapping" {
    for_each = aws_eip.nlb_eip

    content {
      subnet_id     = aws_subnet.k3s-public.id
      allocation_id = subnet_mapping.value.id
    }
  }

 enable_cross_zone_load_balancing = true

  tags = {
    Name = var.lb_name
  }
}

resource "aws_lb_target_group" "tg_30007" {
  provider = aws.region_1
  name     = var.target_group_name
  port     = var.k3s_service_port
  protocol = "TCP"
  vpc_id   = aws_vpc.k3s-vpc.id

  health_check {
    interval            = var.health_check_interval
    protocol            = "TCP"
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    port                = var.k3s_service_port
  }
}

resource "aws_lb_listener" "listener_30007" {
  provider = aws.region_1
  load_balancer_arn = aws_lb.my_nlb.arn
  port              = var.k3s_service_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_30007.arn
  }
}

# Generate a private key for SSH access
resource "tls_private_key" "example1" {
  provider = aws.region_2
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "example1" {
  provider = aws.region_2
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "private_key1" {
  provider = aws.region_2
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
}


resource "aws_vpc" "k3s-vpc-21" {
  provider = aws.region_2
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "k3s-vpc-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "k3s-igw1" {
  provider = aws.region_2
  vpc_id = aws_vpc.k3s-vpc.id

  tags = {
    Name = "k3s-igw"
  }
}

# Create EIP for NAT Gateway

resource "aws_eip" "net-eip5" {
provider = aws.region_2
  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "k3s-nat6" {
  provider = aws.region_2
  allocation_id = aws_eip.net-eip.id
  subnet_id     = aws_subnet.k3s-public.id

  tags = {
    Name = "k3s-nat"
  }
}

# Create EIP for NAT Gateway
resource "aws_eip" "net-eip11" {
  provider = aws.region_2
  tags = {
    Name = "nat-eip1"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "k3s-nat11" {
  provider = aws.region_2
  allocation_id = aws_eip.net-eip1.id
  subnet_id     = aws_subnet.k3s-public.id

  tags = {
    Name = "k3s-nat"
  }
}

# Public Subnet for Bastion Host
resource "aws_subnet" "k3s-public1" {
  provider = aws.region_2
  vpc_id            = aws_vpc.k3s-vpc.id
  cidr_block        = var.public_subnet_a_cidr_block
  availability_zone = var.zone1

  tags = {
    Name = "k3s-public"
  }
}

# Private Subnet for Private EC2 Instance
resource "aws_subnet" "k3s-private1" {
  provider = aws.region_2
  vpc_id            = aws_vpc.k3s-vpc.id
  cidr_block        = var.private_subnet_b_cidr_block
  availability_zone = var.zone1

  tags = {
    Name = "k3s-private"
  }
}

# Public Route Table
resource "aws_route_table" "k3s-rt-public1" {
  provider = aws.region_2
  vpc_id = aws_vpc.k3s-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s-igw.id
  }

     route {
    cidr_block     = "0.0.0.0/16"
    nat_gateway_id = aws_nat_gateway.k3s-nat1.id
  }
  

  tags = {
    Name = "pub-route-table"
  }
}

# Private Route Table (using NAT Gateway)
resource "aws_route_table" "k3s-rt-private1" {
  provider = aws.region_1
  vpc_id = aws_vpc.k3s-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.k3s-nat.id
  }

  tags = {
    Name = "pvt-route-table"
  }
}

# Associate Route Tables with Subnets
resource "aws_route_table_association" "a1" {
  provider = aws.region_2
  subnet_id      = aws_subnet.k3s-public.id
  route_table_id = aws_route_table.k3s-rt-public.id
}

resource "aws_route_table_association" "b1" {
  provider = aws.region_2
  subnet_id      = aws_subnet.k3s-private.id
  route_table_id = aws_route_table.k3s-rt-private.id
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg1" {
  provider = aws.region_2
  name        = "bastion-sg"
  description = "Allow SSH access to the bastion host"
  vpc_id      = aws_vpc.k3s-vpc.id

ingress {
    description = "HTTP PORT"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Load Balancer to K3s"
    from_port   = var.k3s_service_port
    to_port     = var.k3s_service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s API server"
    from_port   = var.k3s_api_port
    to_port     = var.k3s_api_port
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
    Name = "bastion-sg"
  }
}

resource "aws_security_group" "private_sg1" {
  provider = aws.region_2
  name        = "private-sg"
  description = "Allow SSH access from bastion"
  vpc_id      = aws_vpc.k3s-vpc.id

 ingress {
    description = "HTTP PORT"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Load Balancer to K3s"
    from_port   = var.k3s_service_port
    to_port     = var.k3s_service_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "K3s API server"
    from_port   = var.k3s_api_port
    to_port     = var.k3s_api_port
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
    Name = var.sg_name
  }
}

resource "aws_eip" "nlb_eip7" {
  count = 1
tags = {
    Name = "nlb-eip"
  }
}


resource "aws_lb" "my_nlb1" {
  provider = aws.region_2
  name                    = var.lb_name
  internal                = false
  load_balancer_type      = "network"
  enable_deletion_protection = false

  dynamic "subnet_mapping" {
    for_each = aws_eip.nlb_eip

    content {
      subnet_id     = aws_subnet.k3s-public.id
      allocation_id = subnet_mapping.value.id
    }
  }

 enable_cross_zone_load_balancing = true

  tags = {
    Name = var.lb_name
  }
}

resource "aws_lb_target_group" "tg1_30007" {
  provider = aws.region_2
  name     = var.target_group_name
  port     = var.k3s_service_port
  protocol = "TCP"
  vpc_id   = aws_vpc.k3s-vpc.id

  health_check {
    interval            = var.health_check_interval
    protocol            = "TCP"
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    port                = var.k3s_service_port
  }
}

resource "aws_lb_listener" "listener1_30007" {
 provider = aws.region_2
  load_balancer_arn = aws_lb.my_nlb.arn
  port              = var.k3s_service_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_30007.arn
  }
}

# Data source to get the latest AMI for Region 1
data "aws_ami" "latest_region_1_ami" {
  provider = aws.region_1
  most_recent = true
  owners      = [var.region_1_ami_owner]
  filters = {
    name = var.region_1_ami_filter_name
  }
}

# Data source to get the latest AMI for Region 2
data "aws_ami" "latest_region_2_ami" {
  provider = aws.region_2
  most_recent = true
  owners      = [var.region_2_ami_owner]
  filters = {
    name = var.region_2_ami_filter_name
  }
}

# Define Resources for Region 1 (example: Bastion Host, K3s Master, etc.)

resource "aws_instance" "bastion_region_1" {
  provider = aws.region_1
  ami      = data.aws_ami.latest_region_1_ami.id
  instance_type = var.stand_instance_type
  subnet_id = aws_subnet.k3s-public.id
  key_name = aws_key_pair.example.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "Bastion Host Region 1"
  }

  provisioner "file" {
    source      = "${path.module}/${var.key_name}.pem"
    destination = "/tmp/terraform-key.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y htop"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }
}

# Region 2: Bastion Host
resource "aws_instance" "bastion_region_2" {
  provider = aws.region_2
  ami      = data.aws_ami.latest_region_2_ami.id
  instance_type = var.stand_instance_type
  subnet_id = aws_subnet.k3s-public.id
  key_name = aws_key_pair.example.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "Bastion Host Region 2"
  }

  provisioner "file" {
    source      = "${path.module}/${var.key_name}.pem"
    destination = "/tmp/terraform-key.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y htop"
    ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }
}

resource "aws_instance" "k3s_master" {
  provider = aws.region_1
  ami      = data.aws_ami.latest_region_1_ami.id
  instance_type = var.instance_type
  key_name = aws_key_pair.example.key_name
  subnet_id = aws_subnet.k3s-private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "k3s-master"
  }

  provisioner "file" {
    source      = "nginx-deploy.yml"
    destination = "/tmp/nginx-deploy.yml"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.example.private_key_pem
      host        = self.private_ip  # Private IP of the k3s_master node
      bastion_host = aws_eip.bastion_eip.public_ip
      bastion_user = var.ssh_user
      bastion_private_key = tls_private_key.example.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install snapd -y",
      "sudo snap install helm --classic",
      "helm version || echo 'Helm installation failed'",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} INSTALL_K3S_EXEC=\"server --disable=traefik\" sh -",
      "sleep 30",  # Wait for K3s to start
      "sudo cat /var/lib/rancher/k3s/server/node-token > /tmp/node-token", # Save token to a file
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.example.private_key_pem
      host        = self.private_ip  # Private IP of the k3s_master node
      bastion_host = aws_eip.bastion_eip.public_ip
      bastion_user = var.ssh_user
      bastion_private_key = tls_private_key.example.private_key_pem
    }
  }
}

resource "aws_instance" "k3s_worker" {
  count = var.instance_count
  provider = aws.region_1
  ami      = data.aws_ami.latest_region_1_ami.id
  instance_type = var.instance_type
  key_name = aws_key_pair.example.key_name
  associate_public_ip_address = false  # No public IP
  subnet_id = aws_subnet.k3s-private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "k3s-worker-${count.index}"
  }

  provisioner "file" {
    source      = "${path.module}/${var.key_name}.pem"
    destination = "/tmp/${var.key_name}.pem"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.example.private_key_pem
      host        = self.private_ip
      bastion_host = aws_eip.bastion_eip.public_ip
      bastion_user = var.ssh_user
      bastion_private_key = tls_private_key.example.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /tmp/terraform-key.pem",
      "K3S_TOKEN=$(ssh -o StrictHostKeyChecking=no -i /tmp/${var.key_name}.pem ${var.ssh_user}@${aws_instance.k3s_master.private_ip} 'sudo cat /var/lib/rancher/k3s/server/node-token')",
      "K3S_URL=https://${aws_instance.k3s_master.private_ip}:6443",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.example.private_key_pem
      host        = self.private_ip
      bastion_host = aws_eip.bastion_eip.public_ip
      bastion_user = var.ssh_user
      bastion_private_key = tls_private_key.example.private_key_pem
    }
  }
}

# Define Resources for Region 2 (same as for region_1)
resource "aws_instance" "bastion_region_4" {
  provider = aws.region_2
  ami      = data.aws_ami.latest_region_2_ami.id
  instance_type = var.stand_instance_type
  subnet_id = aws_subnet.k3s-public.id
  key_name = aws_key_pair.example.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "Bastion Host Region 2"
  }

  # Repeat provisioners as per region_1
}

resource "aws_instance" "k3s_master_region_2" {
  provider = aws.region_2
  ami      = data.aws_ami.latest_region_2_ami.id
  instance_type = var.instance_type
  key_name = aws_key_pair.example.key_name
  subnet_id = aws_subnet.k3s-private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "k3s-master Region 2"
  }

  # Repeat provisioners as per region_1
}

resource "aws_instance" "k3s_worker_region_2" {
  count = var.instance_count
  provider = aws.region_2
  ami      = data.aws_ami.latest_region_2_ami.id
  instance_type = var.instance_type
  key_name = aws_key_pair.example.key_name
  associate_public_ip_address = false  # No public IP
  subnet_id = aws_subnet.k3s-private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "k3s-worker Region 2-${count.index}"
  }

  # Repeat provisioners as per region_1
}

# Example of Attachments for Load Balancers (same as region_1)
resource "aws_lb_target_group_attachment" "master_attachment_region_1" {
  target_group_arn = aws_lb_target_group.tg_30007.arn
  target_id        = aws_instance.k3s_master.id
  port             = var.k3s_service_port
}

resource "aws_lb_target_group_attachment" "worker_attachments_region_1" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.tg_30007.arn
  target_id        = aws_instance.k3s_worker[count.index].id
  port             = var.k3s_service_port
}
