variable "project_id" {
  description = "The project ID to deploy the resources."
  type        = string
}

variable "region" {
  description = "The region in which to create the resources."
  type        = string
  default     = "europe-north1"
}

variable "wasmcloud_rpc_nats_host" {
  description = "The hostname of the NATS server."
  type        = string
}

variable "wasmcloud_rpc_nats_port" {
  description = "The port of the NATS server."
  type        = string
  default     = "4222"
}

variable "wasmcloud_ctl_nats_host" {
  description = "The hostname of the NATS server for control interface."
  type        = string
}

variable "wasmcloud_ctl_nats_port" {
  description = "The port of the NATS server for control interface."
  type        = string
  default     = "4222"
}

variable "wadm_nats_host" {
  description = "The hostname of the NATS server."
  type        = string
}

variable "wadm_nats_port" {
  description = "The port of the NATS server."
  type        = string
  default     = "4222"
}

variable "version_wasmcloud" {
  description = "The version of wasmcloud to deploy."
  type        = string
  default     = "1.4.0"
}

variable "version_wadm" {
  description = "The version of wadm to deploy."
  type        = string
  default     = "v0.18.0"
}

variable "version_otel_collector" {
  description = "The version of OTEL collector to use."
  type        = string
  default     = "0.111.0"
}

variable "wcrpc_secret_name" {
  description = "The name of the secret to store the wasmcloud rpc credentials."
  type        = string

}

variable "wcctl_secret_name" {
  description = "The name of the secret to store the wasmcloud control plane credentials."
  type        = string
}

variable "wadm_secret_name" {
  description = "The name of the secret to store the wadm credentials."
  type        = string
}

variable "secrets_nats_kv_secret_name" {
  description = "The name of the secret with NATS Credentials used by secrets-nats-kv to connect to NATS."
  type        = string
}

variable "number_of_wasmcloud_hosts" {
  description = "Number of wasmcloud hosts to run."
  type        = number
  default     = 1
}

variable "number_of_wadm_hosts" {
  description = "Number of wadm hosts to run."
  type        = number
  default     = 1
}

variable "number_of_secrets_nats_kv_hosts" {
  description = "Number of secret-nats-kv(instances) hosts to run."
  type        = number
  default     = 1
}

variable "transit_xkey_seed_secret_name" {
  description = "Name of secret containing the TRANSIT_XKEY_Seed value used by secrets-nats-kv."
  type        = string
}

variable "encryption_xkey_seed_secret_name" {
  description = "Name of secret containing the ENCRYPTION_XKEY_SEED value used by secrets-nats-kv."
  type        = string
}

