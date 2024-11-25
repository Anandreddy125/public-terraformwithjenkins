variable "region" {
  description = "AWS Region"
  default     = "ap-south-1"
}


variable "zone1" {
  description = "AWS Zone 1"
  default     = "ap-south-1a"
}

variable "zone2" {
  description = "AWS Zone 2"
  default     = "ap-south-1b"
}

variable "vpc_cidr_block" {
  description = "VPC network"
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr_block" {
  description = "Public Subnet A"
  default     = "10.0.1.0/24"
}

variable "private_subnet_b_cidr_block" {
  description = "Public Subnet B"
  default     = "10.0.2.0/24"
}

variable "stand_ami_id" {
  description = "AMI ID for the bastion host"
  type        = string
  default     = "ami-0c2af51e265bd5e0e" 
}

variable "stand_instance_type" {
  description = "The instance type for the stand instance"
  type        = string
  default     = "t2.micro"  # You can set a default value if desired
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

variable "ami_id" {
  description = "AMI ID to use for the EC2 instances"
  type        = string
  default     = "ami-0c2af51e265bd5e0e"  # Ensure this AMI ID exists in your region
}

variable "instance_type" {
  description = "Instance type for the EC2 instances"
  type        = string
  default     = "t2.medium"
}

variable "key_name" {
  description = "Key pair name for the EC2 instances"
  type        = string
  default     = "terraform-key"
}

variable "instance_count" {
  description = "number of  ec2 instance to create"
  type = number
  default = 1
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
  default     = "private-sg"  # Optional default value
}
