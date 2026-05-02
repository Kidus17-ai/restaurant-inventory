variable "name_prefix" {
  description = "Prefix for naming all resources"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to deploy into"
  type        = list(string)
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}