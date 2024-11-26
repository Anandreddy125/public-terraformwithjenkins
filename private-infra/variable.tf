variable "region_1" {
  description = "The first AWS region"
  type        = string
  default     = "us-west-2"  # You can set a default or leave it to be provided later
}

variable "region_2" {
  description = "The second AWS region"
  type        = string
  default     = "us-east-1"  # You can set a default or leave it to be provided later
}

# AWS Provider Configuration Variables
variable "vpc_cidr_block" {
  description = "VPC network"
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr_block" {
  description = "Public Subnet A"
  default     = "10.0.1.0/24"
}

variable "private_subnet_b_cidr_block" {
  description = "Private Subnet B"
  default     = "10.0.2.0/24"
}

variable "lb_name" {
  description = "Load Balancer Name"
  type        = string
  default     = "my-nlb"
}

variable "k3s_service_port1" {
  description = "Port for the K3s service"
  type        = number
  default     = 80
}

variable "target_group_name" {
  description = "Target Group Name"
  type        = string
  default     = "k3s-tg"
}

variable "k3s_service_port" {
  description = "Port for the K3s service"
  type        = number
  default     = 30007
}

variable "k3s_api_port" {
  description = "API server port for K3s"
  type        = number
  default     = 6443
}

variable "health_check_interval" {
  description = "Interval for health checks"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout for health checks"
  type        = number
  default     = 5
}

variable "healthy_threshold" {
  description = "Healthy threshold for health checks"
  type        = number
  default     = 2
}

variable "unhealthy_threshold" {
  description = "Unhealthy threshold for health checks"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "Key pair name for the EC2 instances"
  type        = string
  default     = "terraform-key"
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 3
}

variable "ssh_user" {
  description = "SSH user for connecting to instances"
  type        = string
  default     = "ubuntu"
}

variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "v1.25.4+k3s1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "anrs-xyz"
}

variable "sg_name" {
  description = "The name of the security group"
  type        = string
  default     = "private-sg"
}

variable "stand_instance_type" {
  description = "The instance type for the bastion host"
  type        = string
  default     = "t2.micro"
}

variable "instance_type" {
  description = "The instance type for the k3s nodes"
  type        = string
  default     = "t2.micro"
}

# Region-specific AMI variables
variable "region_1_ami_id" {
  description = "AMI ID for region 1"
  type        = string
}

variable "region_2_ami_id" {
  description = "AMI ID for region 2"
  type        = string
}

variable "region_1_ami_filter_name" {
  description = "AMI filter name pattern for region 1"
  type        = string
  default     = "ubuntu/images/*ubuntu-xenial-16.04-amd64-server-*"
}

variable "region_2_ami_filter_name" {
  description = "AMI filter name pattern for region 2"
  type        = string
  default     = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
}

variable "region_1_ami_owner" {
  description = "AMI owner for region 1"
  type        = string
  default     = "amazon"
}

variable "region_2_ami_owner" {
  description = "AMI owner for region 2"
  type        = string
  default     = "amazon"
}

