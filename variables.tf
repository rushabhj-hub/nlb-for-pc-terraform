variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID where resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the NLB"
  type        = list(string)
}

variable "target_ips" {
  description = "List of IPs to be registered as targets"
  type        = list(string)
}


variable "pc_target_ips" {
  description = "List of IPs to be registered as targets"
  type        = list(string)
}

