# Generate a private key for SSH access
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "example" {
  key_name   = var.key_name
  public_key = tls_private_key.example.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "private_key" {
  content  = tls_private_key.example.private_key_pem
  filename = "${path.module}/${var.key_name}.pem"
}

# VPC
resource "aws_vpc" "k3s-vpc" {
  cidr_block = var.vpc_cidr_block
  
  tags = {
    Name = "k3s-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "k3s-igw" {
  vpc_id = aws_vpc.k3s-vpc.id

  tags = {
    Name = "k3s-igw"
  }
}

# Create EIP for NAT Gateway
resource "aws_eip" "net-eip" {
  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "k3s-nat" {
  allocation_id = aws_eip.net-eip.id
  subnet_id     = aws_subnet.k3s-public.id

  tags = {
    Name = "k3s-nat"
  }
}

# Create EIP for NAT Gateway
resource "aws_eip" "net-eip1" {
  tags = {
    Name = "nat-eip1"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "k3s-nat1" {
  allocation_id = aws_eip.net-eip1.id
  subnet_id     = aws_subnet.k3s-public.id

  tags = {
    Name = "k3s-nat"
  }
}

# Public Subnet for Bastion Host
resource "aws_subnet" "k3s-public" {
  vpc_id            = aws_vpc.k3s-vpc.id
  cidr_block        = var.public_subnet_a_cidr_block
  availability_zone = var.zone1

  tags = {
    Name = "k3s-public"
  }
}

# Private Subnet for Private EC2 Instance
resource "aws_subnet" "k3s-private" {
  vpc_id            = aws_vpc.k3s-vpc.id
  cidr_block        = var.private_subnet_b_cidr_block
  availability_zone = var.zone1

  tags = {
    Name = "k3s-private"
  }
}

# Public Route Table
resource "aws_route_table" "k3s-rt-public" {
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
  subnet_id      = aws_subnet.k3s-public.id
  route_table_id = aws_route_table.k3s-rt-public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.k3s-private.id
  route_table_id = aws_route_table.k3s-rt-private.id
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
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
  load_balancer_arn = aws_lb.my_nlb.arn
  port              = var.k3s_service_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_30007.arn
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = var.stand_ami_id
  instance_type          = var.stand_instance_type
  subnet_id              = aws_subnet.k3s-public.id
  key_name               = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Bastion Host"
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
      "sudo apt-get install -y htop"  # Add any utilities needed for the bastion host
    ]
   connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = tls_private_key.example.private_key_pem
      host        = self.public_ip
    }
  }
}

resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  tags = {
    Name = "bastion-eip"
  }
}

# Private EC2 Instances
resource "aws_instance" "k3s_master" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.example.key_name
  subnet_id                   = aws_subnet.k3s-private.id
  vpc_security_group_ids      = [aws_security_group.private_sg.id]

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
      bastion_host        = aws_eip.bastion_eip.public_ip
      #bastion_host = aws_instance.bastion.public_ip  # Use bastion for SSH
      bastion_user = var.ssh_user  # SSH user for bastion host
      bastion_private_key = tls_private_key.example.private_key_pem  # Key for bastion host
    }
  }

  provisioner "file" {
    source      = "nginx-service.yml"
    destination = "/tmp/nginx-service.yml"

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.example.private_key_pem
      host        = self.private_ip  # Private IP of the k3s_master node
      bastion_host        = aws_eip.bastion_eip.public_ip
    # bastion_host = aws_instance.bastion.public_ip  # Use bastion for SSH
      bastion_user = var.ssh_user  # SSH user for bastion host
      bastion_private_key = tls_private_key.example.private_key_pem  # Key for bastion host
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install snapd -y",
      "sudo snap install helm --classic",
     # "git clone https://${data.vault_kv_secret_v2.example.data["Anandreddy125"]}@github.com/Anandreddy125/private-repo.git /tmp/anrs",
      "helm version || echo 'Helm installation failed'",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} INSTALL_K3S_EXEC=\"server --disable=traefik\" sh -",
      "sleep 30", # Wait for K3s to start
      "sudo cat /var/lib/rancher/k3s/server/node-token > /tmp/node-token", # Save token to a file
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_user
      private_key = tls_private_key.example.private_key_pem
      host        = self.private_ip  # Private IP of the k3s_master node
      bastion_host        = aws_eip.bastion_eip.public_ip
      #bastion_host = aws_instance.bastion.public_ip  # Use bastion for SSH
      bastion_user = var.ssh_user  # SSH user for bastion host
      bastion_private_key = tls_private_key.example.private_key_pem  # Key for bastion host
    }
  }
}

# Private EC2 Instances
# Update the reference from k3s_master to k3s_backend
resource "aws_instance" "k3s_worker" {
  count                       = var.instance_count
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.example.key_name
  associate_public_ip_address = false  # No public IP
  subnet_id                   = aws_subnet.k3s-private.id # Place in private subnet
  vpc_security_group_ids      = [aws_security_group.private_sg.id]

  tags = {
    Name = "k3s-worker-${count.index}"
  }

  provisioner "file" {
    source      = "${path.module}/${var.key_name}.pem"
    destination = "/tmp/${var.key_name}.pem"

    connection {
      type                 = "ssh"
      user                 = var.ssh_user
      private_key          = tls_private_key.example.private_key_pem
      host                 = self.private_ip  # Private IP
      bastion_host        = aws_eip.bastion_eip.public_ip
      #bastion_host         = aws_instance.bastion.public_ip  # Bastion host for SSH
      bastion_user         = var.ssh_user
      bastion_private_key  = tls_private_key.example.private_key_pem
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /tmp/terraform-key.pem",
      # Corrected reference to k3s_backend
      "K3S_TOKEN=$(ssh -o StrictHostKeyChecking=no -i /tmp/${var.key_name}.pem ${var.ssh_user}@${aws_instance.k3s_master.private_ip} 'sudo cat /var/lib/rancher/k3s/server/node-token')",
      "K3S_URL=https://${aws_instance.k3s_master.private_ip}:6443",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${var.k3s_version} K3S_URL=$K3S_URL K3S_TOKEN=$K3S_TOKEN sh -"
    ]

    connection {
      type                 = "ssh"
      user                 = var.ssh_user
      private_key          = tls_private_key.example.private_key_pem
      host                 = self.private_ip  # Private IP of worker node
      bastion_host        = aws_eip.bastion_eip.public_ip
    # bastion_host         = aws_instance.bastion.public_ip  # Bastion host
      bastion_user         = var.ssh_user
      bastion_private_key  = tls_private_key.example.private_key_pem
    }
  }
}



resource "aws_lb_target_group_attachment" "master_attachment" {
  target_group_arn = aws_lb_target_group.tg_30007.arn
  target_id        = aws_instance.k3s_master.id
  port             = var.k3s_service_port
}

resource "aws_lb_target_group_attachment" "worker_attachments" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.tg_30007.arn
  target_id        = aws_instance.k3s_worker[count.index].id
  port             = var.k3s_service_port
}
