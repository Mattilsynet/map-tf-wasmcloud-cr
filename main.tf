locals {
  wasmcloud_service_name       = "wasmcloud"
  wadm_service_name            = "wadm"
  secrets_nats_kv_service_name = "secrets-nats-kv"

  secrets_nats_kv_creds_name = "secrets.creds"
  secrets_nats_kv_creds_path = "/etc/nats/secret-creds"

  secrets_nats_kv_transit_secret_name    = "secrets-nats-kv-transit-seed"
  secrets_nats_kv_encryption_secret_name = "secrets-nats-kv-encryption-seed"

  wasmcloud_rpc_nats_creds_name = "rpc-nats.creds"
  wasmcloud_rpc_nats_creds_path = "/etc/nats/rpc-creds"

  wasmcloud_ctl_nats_creds_name = "ctl-nats.creds"
  wasmcloud_ctl_nats_creds_path = "/etc/nats/ctl-creds"

  wadm_nats_creds_name = "ctl-nats.creds"
  wadm_nats_creds_path = "/etc/nats/wadm-creds"

  otel_config_name = "otel-config.yaml"
  otel_config_path = "/etc/otelcol"

}

### Google Cloud Services

resource "google_project_service" "gc_monitoring" {
  project            = var.project_id
  service            = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "gc_trace" {
  project            = var.project_id
  service            = "cloudtrace.googleapis.com"
  disable_on_destroy = false
}

### Service Accounts

resource "google_service_account" "wasmcloud_service_sa" {
  account_id   = "wasmcloud-service"
  display_name = "wasmcloud-service"
  description  = "Service Account for cloud run service: ${local.wasmcloud_service_name}"
  project      = var.project_id
}

resource "google_service_account" "wadm_service_sa" {
  account_id   = "wadm-service"
  display_name = "wadm-service"
  description  = "Service Account for cloud run service: ${local.wadm_service_name}"
  project      = var.project_id
}

resource "google_service_account" "secrets_nats_kv" {
  account_id   = "secrets-nats-kv"
  display_name = "secrets-nats-kv"
  description  = "Service Account for cloud run service ${local.secrets_nats_kv_service_name}"
  project      = var.project_id
}

### Service Account Tokens [UGLY]

resource "google_service_account_key" "wasmcloud_service_sa_key" {
  service_account_id = google_service_account.wasmcloud_service_sa.id
}

resource "google_secret_manager_secret" "wasmcloud_service_account_token" {
  secret_id = "wasmcloud-service-account-token"
  project   = var.project_id
  replication {
    user_managed {
      dynamic "replicas" {
        for_each = var.regions
        content {
          location = replicas.value
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "wasmcloud_service_account_key_secret_version" {
  secret      = google_secret_manager_secret.wasmcloud_service_account_token.id
  secret_data = base64decode(google_service_account_key.wasmcloud_service_sa_key.private_key)
}

### Artifact Registry IAM

// TODO: the gar stuff should be taken out, to specific to our needs
data "google_artifact_registry_repository" "gar_repo" {
  project       = "artifacts-352708"
  location      = var.gar_region
  repository_id = "map"
}

resource "google_artifact_registry_repository_iam_member" "gar_repo_member" {
  project    = "artifacts-352708"
  repository = data.google_artifact_registry_repository.gar_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.wasmcloud_service_sa.email}"
}

### IAM Roles

resource "google_project_iam_member" "wasmcloud_iam_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.wasmcloud_service_sa.email}"
}

resource "google_project_iam_member" "wadm_iam_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.wadm_service_sa.email}"
}

resource "google_project_iam_member" "wasmcloud_iam_cloudtrace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.wasmcloud_service_sa.email}"
}

resource "google_project_iam_member" "wadm_iam_cloudtrace_agent" {
  project = var.project_id
  role    = "roles/cloudtrace.agent"
  member  = "serviceAccount:${google_service_account.wadm_service_sa.email}"
}

resource "google_project_iam_member" "wasmcloud_iam_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.wasmcloud_service_sa.email}"
}

resource "google_project_iam_member" "wadm_iam_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.wadm_service_sa.email}"
}

### Secrets, NATS credentials

data "google_secret_manager_secret" "wasmcloud_ctl_nats_creds" {
  secret_id = var.wcctl_secret_name
  project   = var.project_id
}

data "google_secret_manager_secret" "wasmcloud_rpc_nats_creds" {
  secret_id = var.wcrpc_secret_name
  project   = var.project_id
}

data "google_secret_manager_secret" "wadm_nats_creds" {
  secret_id = var.wadm_secret_name
  project   = var.project_id
}

data "google_secret_manager_secret" "secrets_nats_kv_nats_creds" {
  secret_id = var.secrets_nats_kv_secret_name
  project   = var.project_id
}

### Secrets, secrets-nats-kv

data "google_secret_manager_secret" "secrets_nats_kv_transit_secret" {
  secret_id = var.secrets_nats_kv_transit_secret_name
  project   = var.project_id
}

data "google_secret_manager_secret" "secrets_nats_kv_encryption_secret" {
  secret_id = var.secrets_nats_kv_encryption_secret_name
  project   = var.project_id
}
### Secrets, Configs

locals {
  otel_config = templatefile(
    "${path.module}/resources/otel-config.yaml",
    {
      project_id = var.project_id
    }
  )
}

resource "google_secret_manager_secret" "wasmcloud_cr_otel_config" {
  secret_id = "wasmcloud-cr-otel-config"
  project   = var.project_id
  replication {
    user_managed {
      dynamic "replicas" {
        for_each = var.regions
        content {
          location = replicas.value
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "wasmcloud_otel_config_version" {
  secret      = google_secret_manager_secret.wasmcloud_cr_otel_config.id
  secret_data = local.otel_config
}


### Secrets IAM

locals {
  wasmcloud_secrets = {
    "wasmcloud_ctl_nats_creds"        = data.google_secret_manager_secret.wasmcloud_rpc_nats_creds.secret_id,
    "wasmcloud_rpc_nats_creds"        = data.google_secret_manager_secret.wasmcloud_ctl_nats_creds.secret_id,
    "wasmcloud_cr_otel_config"        = google_secret_manager_secret.wasmcloud_cr_otel_config.id,
    "wasmcloud_service_account_token" = google_secret_manager_secret.wasmcloud_service_account_token.id,
  }

  wadm_secrets = {
    "wadm_nats_creds"          = data.google_secret_manager_secret.wadm_nats_creds.secret_id,
    "wasmcloud_cr_otel_config" = google_secret_manager_secret.wasmcloud_cr_otel_config.id,
  }

  secrets_nats_kv_secrets = {
    "nats_creds"      = data.google_secret_manager_secret.secrets_nats_kv_nats_creds.id,
    "transit_seed"    = data.google_secret_manager_secret.secrets_nats_kv_transit_secret.id,
    "encryption_seed" = data.google_secret_manager_secret.secrets_nats_kv_encryption_secret.id,
  }
}

resource "google_secret_manager_secret_iam_member" "wasmcloud_secret_access" {
  for_each = local.wasmcloud_secrets

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.wasmcloud_service_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "wadm_secret_access" {
  for_each = local.wadm_secrets

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.wadm_service_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "secrets_nats_kv_secret_access" {
  for_each = local.secrets_nats_kv_secrets

  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.secrets_nats_kv.email}"
}

### Services

resource "google_cloud_run_v2_service" "wasmcloud_v2_service" {
  for_each = toset(var.regions)

  name                = "wasmcloud-${each.key}"
  location            = each.key
  project             = var.project_id
  deletion_protection = false

  depends_on = [google_secret_manager_secret_version.wasmcloud_otel_config_version]

  template {
    service_account = google_service_account.wasmcloud_service_sa.email

    scaling {
      min_instance_count = var.number_of_wasmcloud_hosts
      max_instance_count = var.number_of_wasmcloud_hosts
    }

    volumes {
      name = "wasmcloud-rpc-nats-credentials"
      secret {
        secret       = data.google_secret_manager_secret.wasmcloud_rpc_nats_creds.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.wasmcloud_rpc_nats_creds_name
        }
      }
    }

    volumes {
      name = "wasmcloud-ctl-nats-credentials"
      secret {
        secret       = data.google_secret_manager_secret.wasmcloud_ctl_nats_creds.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.wasmcloud_ctl_nats_creds_name
        }
      }
    }

    volumes {
      name = "otel-config"
      secret {
        secret       = google_secret_manager_secret.wasmcloud_cr_otel_config.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.otel_config_name
        }
      }
    }

    containers {
      name  = "wasmcloud"
      image = "europe-north1-docker.pkg.dev/artifacts-352708/ghcr-test/wasmcloud/wasmcloud:${var.version_wasmcloud}"
      //image = "ghcr.io/wasmcloud/wasmcloud:${var.version_wasmcloud}"

      #args = [
      #  "--label", "region=${each.key}",
      #  "--label", "cloud=gcp",
      #]

      startup_probe {
        initial_delay_seconds = 5
        timeout_seconds       = 20
        period_seconds        = 60
        failure_threshold     = 1
        tcp_socket {
          port = 8080
        }
      }

      resources {
        limits = {
          cpu    = "2000m"
          memory = "4Gi"
        }
        cpu_idle = false
      }

      ports {
        name           = "http1"
        container_port = 8080
      }


      env {
        name  = "WASMCLOUD_LABEL_cloud"
        value = "gcp"
      }

      env {
        name  = "WASMCLOUD_LABEL_region"
        value = each.key
      }

      env {
        name  = "RUST_LOG"
        value = "info,hyper=info,async_nats=info,oci_distribution=info,cranelift_codegen=warn"
      }
      env {
        name  = "WASMCLOUD_HTTP_ADMIN"
        value = "0.0.0.0:8080"
      }

      env {
        name  = "WASMCLOUD_RPC_HOST"
        value = var.wasmcloud_rpc_nats_host
      }
      env {
        name  = "WASMCLOUD_RPC_PORT"
        value = var.wasmcloud_rpc_nats_port
      }
      env {
        name  = "WASMCLOUD_RPC_TLS"
        value = "true"
      }
      env {
        name  = "WASMCLOUD_CTL_HOST"
        value = var.wasmcloud_ctl_nats_host
      }
      env {
        name  = "WASMCLOUD_CTL_PORT"
        value = var.wasmcloud_ctl_nats_port
      }
      env {
        name  = "WASMCLOUD_CTL_TLS"
        value = "true"
      }
      env {
        name  = "WASMCLOUD_RPC_CREDS"
        value = "${local.wasmcloud_rpc_nats_creds_path}/${local.wasmcloud_rpc_nats_creds_name}"
      }
      env {
        name  = "WASMCLOUD_CTL_CREDS"
        value = "${local.wasmcloud_ctl_nats_creds_path}/${local.wasmcloud_ctl_nats_creds_name}"
      }
      env {
        name  = "WASMCLOUD_LOG_LEVEL"
        value = "info"
      }
      env {
        name  = "WASMCLOUD_ALLOW_FILE_LOAD"
        value = "true"
      }
      env {
        name  = "WASMCLOUD_OBSERVABILITY_ENABLED"
        value = "true"
      }

      env {
        name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
        value = "http://localhost:4318"
      }

      env {
        name  = "WASMCLOUD_OCI_REGISTRY"
        value = "europe-north1-docker.pkg.dev"
      }

      env {
        name  = "WASMCLOUD_OCI_REGISTRY_USER"
        value = "oauth2accesstoken"
      }

      env {
        name  = "WASMCLOUD_SECRETS_TOPIC"
        value = "wasmcloud.secrets"
      }

      env {
        name = "WASMCLOUD_OCI_REGISTRY_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.wasmcloud_service_account_token.id
            version = "latest"
          }
        }
      }

      volume_mounts {
        name       = "wasmcloud-rpc-nats-credentials"
        mount_path = local.wasmcloud_rpc_nats_creds_path
      }

      volume_mounts {
        name       = "wasmcloud-ctl-nats-credentials"
        mount_path = local.wasmcloud_ctl_nats_creds_path
      }
    }

    containers {
      image = "otel/opentelemetry-collector-contrib:${var.version_otel_collector}"

      args = ["--config=${local.otel_config_path}/${local.otel_config_name}"]

      volume_mounts {
        name       = "otel-config"
        mount_path = local.otel_config_path
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = false
      }
    }
  }
}

resource "google_cloud_run_v2_service" "wadm_v2_service" {
  for_each = toset(var.regions)

  name                = "wadm-${each.key}"
  location            = each.key
  project             = var.project_id
  deletion_protection = false

  depends_on = [google_secret_manager_secret_version.wasmcloud_otel_config_version]

  template {
    service_account = google_service_account.wadm_service_sa.email

    scaling {
      min_instance_count = var.number_of_wadm_hosts
      max_instance_count = var.number_of_wadm_hosts
    }


    volumes {
      name = "wadm-nats-credentials"
      secret {
        secret       = data.google_secret_manager_secret.wadm_nats_creds.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.wadm_nats_creds_name
        }
      }
    }

    volumes {
      name = "otel-config"
      secret {
        secret       = google_secret_manager_secret.wasmcloud_cr_otel_config.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.otel_config_name
        }
      }
    }


    containers {
      image = "otel/opentelemetry-collector-contrib:${var.version_otel_collector}"

      args = ["--config=${local.otel_config_path}/${local.otel_config_name}"]

      volume_mounts {
        name       = "otel-config"
        mount_path = local.otel_config_path
      }

      ports {
        name           = "http1"
        container_port = 4318
      }

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        cpu_idle = false
      }


      startup_probe {
        initial_delay_seconds = 5
        timeout_seconds       = 20
        period_seconds        = 60
        failure_threshold     = 1
        tcp_socket {
          port = 4318
        }
      }
    }


    containers {
      name  = "wadm"
      image = "europe-north1-docker.pkg.dev/artifacts-352708/ghcr-test/wasmcloud/wadm:${var.version_wadm}"
      //image = "ghcr.io/wasmcloud/wadm:${var.version_wadm}"

      resources {
        limits = {
          cpu    = "1000m"
          memory = "2Gi"
        }
        cpu_idle = false
      }

      env {
        name  = "WADM_NATS_SERVER"
        value = "${var.wadm_nats_host}:${var.wadm_nats_port}"
      }
      env {
        name  = "WADM_NATS_CREDS_FILE"
        value = "${local.wadm_nats_creds_path}/${local.wadm_nats_creds_name}"
      }
      env {
        name  = "WADM_STRUCTURED_LOGGING"
        value = "true"
      }
      env {
        name  = "WADM_TRACING_ENABLED"
        value = "true"
      }

      volume_mounts {
        name       = "wadm-nats-credentials"
        mount_path = local.wadm_nats_creds_path
      }
    }

  }
}
resource "google_cloud_run_v2_service" "secrets_nats_kv_service" {
  for_each = toset(var.regions)

  name                = "secrets-nats-kv-${each.key}"
  location            = each.key
  project             = var.project_id
  deletion_protection = false

  template {
    service_account = google_service_account.secrets_nats_kv.email

    volumes {
      name = "nats-creds"
      secret {
        secret       = data.google_secret_manager_secret.secrets_nats_kv_nats_creds.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.secrets_nats_kv_creds_name
        }
      }
    }

    scaling {
      min_instance_count = var.number_of_secrets_nats_kv_instances
      max_instance_count = var.number_of_secrets_nats_kv_instances
    }

    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports {
        name           = "http1"
        container_port = 8080
      }

      resources {
        limits = {
          "memory" = "512Mi",
          "cpu"    = "1"
        }
      }
    }
    containers {
      image = "europe-north1-docker.pkg.dev/artifacts-352708/map/secrets-nats-kv:latest"

      args = ["run", "--nats-address", "tls://${var.wadm_nats_host}:${var.wadm_nats_port}"]

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = false
      }

      #      env {
      #        name  = "NATS_ADDRESS"
      #        value = "tls://${var.wadm_nats_host}:4222"
      #      }

      env {
        name  = "NATS_CREDSFILE"
        value = "${local.secrets_nats_kv_creds_path}/${local.secrets_nats_kv_creds_name}"
      }

      env {
        name = "TRANSIT_XKEY_SEED"
        value_source {
          secret_key_ref {
            secret  = data.google_secret_manager_secret.secrets_nats_kv_transit_secret.id
            version = "latest"
          }
        }
      }

      env {
        name = "ENCRYPTION_XKEY_SEED"
        value_source {
          secret_key_ref {
            secret  = data.google_secret_manager_secret.secrets_nats_kv_encryption_secret.id
            version = "latest"
          }
        }
      }

      volume_mounts {
        name       = "nats-creds"
        mount_path = local.secrets_nats_kv_creds_path
      }
    }
  }
}
