output "bastion_public_ip_region_1" {
  value = aws_instance.bastion_region_1.public_ip
}

output "bastion_public_ip_region_2" {
  value = aws_instance.bastion_region_2.public_ip
}

output "k3s_master_private_ip_region_1" {
  value = aws_instance.k3s_master_region_1.private_ip
}

output "k3s_master_private_ip_region_2" {
  value = aws_instance.k3s_master_region_2.private_ip
}
