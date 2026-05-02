variable "name_prefix" {
  description = "Prefix for naming all resources"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs for ECS"
  type        = list(string)
}

variable "app_port" {
  description = "Port the application runs on"
  type        = number
  default     = 5001
}

variable "app_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "ECS task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 512
}

variable "db_url" {
  description = "Database connection URL"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Flask secret key"
  type        = string
  sensitive   = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

variable "alert_email" {
  description = "Email address for low stock alerts"
  type        = string
}