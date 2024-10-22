# map-tf-wasmcloud-cr

[map-tf-wasmcloud-cr] terraform module provisions wasmcloud and wadm instances as
Google Cloud Run services.

## Research notes

Think this is about wasmcloud binary and not wash up: 
https://wasmcloud.com/docs/reference/host-config 


That above seems severly outdated. Investiage the binary from https://github.com/wasmCloud/wasmCloud/releases/tag/v1.3.1 

## Usage

## Additional information

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.5 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 6.3.0, < 7.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 6.3.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 6.3.0, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service.wadm_v2_service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service.wasmcloud_v2_service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_project_iam_member.wadm_iam_cloudtrace_agent](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.wadm_iam_log_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.wadm_iam_metric_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.wasmcloud_iam_cloudtrace_agent](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.wasmcloud_iam_log_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_project_iam_member.wasmcloud_iam_metric_writer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_secret_manager_secret.wadm_cr_nats_creds](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.wasmcloud_cr_nats_config](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret.wasmcloud_cr_nats_creds](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret) | resource |
| [google_secret_manager_secret_iam_member.wadm_secret_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_iam_member.wasmcloud_secret_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_secret_manager_secret_version.wadm_nats_cr_creds_version](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.wasmcloud_cr_nats_creds_version](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_secret_manager_secret_version.wasmcloud_nats_config_version](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_version) | resource |
| [google_service_account.wadm_service_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.wasmcloud_service_sa](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The project ID to deploy the resources. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region in which to create the resources. | `string` | `"europe-north1"` | no |
| <a name="input_version_nats"></a> [version\_nats](#input\_version\_nats) | The version of NATS to deploy. | `string` | `"latest"` | no |
| <a name="input_version_wadm"></a> [version\_wadm](#input\_version\_wadm) | The version of wadm to deploy. | `string` | `"latest"` | no |
| <a name="input_version_wasmcloud"></a> [version\_wasmcloud](#input\_version\_wasmcloud) | The version of wasmcloud to deploy. | `string` | `"latest"` | no |
| <a name="input_wadm_nats_host"></a> [wadm\_nats\_host](#input\_wadm\_nats\_host) | The hostname of the NATS server. | `string` | n/a | yes |
| <a name="input_wadm_nats_port"></a> [wadm\_nats\_port](#input\_wadm\_nats\_port) | The port of the NATS server. | `string` | `"4222"` | no |
| <a name="input_wasmcloud_nats_host"></a> [wasmcloud\_nats\_host](#input\_wasmcloud\_nats\_host) | The hostname of the NATS server. | `string` | n/a | yes |
| <a name="input_wasmcloud_nats_port"></a> [wasmcloud\_nats\_port](#input\_wasmcloud\_nats\_port) | The port of the NATS server. | `string` | `"4222"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->