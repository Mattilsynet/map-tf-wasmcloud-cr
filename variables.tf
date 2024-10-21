variable "project_id" {
  description = "The project ID to deploy the resources."
  type        = string
}

variable "region" {
  description = "The region in which to create the resources."
  type        = string
  default     = "europe-north1"
}

variable "wasmcloud_nats_host" {
  description = "The hostname of the NATS server."
  type        = string
  default     = "localhost"
}

variable "wadm_nats_host" {
  description = "The hostname of the NATS server."
  type        = string
}

variable "version_wasmcloud" {
  description = "The version of wasmcloud to deploy."
  type        = string
  default     = "latest"
}

variable "version_wadm" {
  description = "The version of wadm to deploy."
  type        = string
  default     = "latest"
}

variable "version_nats" {
  description = "The version of NATS to deploy."
  type        = string
  default     = "latest"
}
