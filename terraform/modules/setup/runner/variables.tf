variable "build_id" {
  type        = string
  description = "The benchmarking run ID"
}

variable "client_name" {
  type        = string
  description = "The name of the client"
}

variable "client_image" {
  type        = string
  description = "The fully qualified Docker image with the client"
}

variable "client_commit" {
  type        = string
  description = "The client commit SHA1"
}

variable "data_source" {
  type        = string
  description = "The path to the benchmarking data"
}

variable "target_urls" {
  type        = string
  description = "The list of target URLs, joined by comma"
}

variable "target_service_type" {
  type        = string
  description = "The type of the target service (elasticsearch, mock, ...)"
}

variable "target_service_name" {
  type        = string
  description = "The name of the target service (elasticsearch, nginx, ...)"
}

variable "target_service_version" {
  type        = string
  description = "The version of the target service"
}

variable "target_service_os_family" {
  type        = string
  description = "The OS family of the target service"
}

variable "cloud_provider" {
  type        = string
  description = "The name of the cloud provider (gcp, aws, ...)"
}

variable "cloud_region" {
  type        = string
  description = "The region where the service is running"
}


variable "cloud_zone" {
  type        = string
  description = "The zone where the service is running"
}

variable "cloud_instance_name" {
  type        = string
  description = "The instance name of the service"
}

variable "cloud_machine_type" {
  type        = string
  description = "The instance type of the service"
}
