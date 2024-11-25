# Output the Elastic IP for the NAT Gateway
output "nat_gateway_eip" {
  value = aws_eip.net-eip.public_ip
  description = "Elastic IP address of the NAT Gateway"
}

# Output the Elastic IP for the second NAT Gateway
output "nat_gateway_eip1" {
  value = aws_eip.net-eip1.public_ip
  description = "Elastic IP address of the second NAT Gateway"
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
  description = "Public IP of the Bastion host"
}

output "load_balancer_dns" {
  value = aws_lb.my_nlb.dns_name
  description = "DNS Name of the Load Balancer"
}

# Output the private IP of the Bastion EC2 instance
output "bastion_private_ip" {
  value       = aws_instance.bastion.private_ip
  description = "Private IP address of the Bastion EC2 instance"
}

# Output the instance ID of the Bastion EC2 instance
output "bastion_instance_id" {
  value       = aws_instance.bastion.id
  description = "Instance ID of the Bastion EC2 instance"
}

# Output the private IP of the K3s master node
output "k3s_master_private_ip" {
  value = aws_instance.k3s_master.private_ip
}

# Output the private IPs of all K3s worker nodes
output "k3s_worker_private_ips" {
  value = [for instance in aws_instance.k3s_worker : instance.private_ip]
}

