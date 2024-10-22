locals {
  wasmcloud_service_name = "wasmcloud"
  wadm_service_name      = "wadm"

  wasmcloud_nats_creds_name = "rpc-nats.creds"
  wasmcloud_nats_creds_path = "/etc/nats/rpc-creds"

  wadm_nats_creds_name = "ctl-nats.creds"
  wadm_nats_creds_path = "/etc/nats/ctl-creds"

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

# This secret is used by the wasmcloud deployment nats server as leaf node credentials.
resource "google_secret_manager_secret" "wasmcloud_cr_nats_creds" {
  secret_id = "wasmcloud-cr-nats-creds"
  project   = var.project_id
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

# This secret is used by wadm directly to the central NATS infrastructure.
resource "google_secret_manager_secret" "wadm_cr_nats_creds" {
  secret_id = "wadm-cr-nats-creds"
  project   = var.project_id
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "wasmcloud_cr_nats_creds_version" {
  secret      = google_secret_manager_secret.wasmcloud_cr_nats_creds.id
  secret_data = "Check the docs and to create a nats user with proper credentials."
}

resource "google_secret_manager_secret_version" "wadm_nats_cr_creds_version" {
  secret      = google_secret_manager_secret.wadm_cr_nats_creds.id
  secret_data = "Check the docs and to create a nats user with proper credentials."
}

### Secrets, Configs

locals {
  nats_config = templatefile(
    "${path.module}/resources/nats.conf",
    {
      project_id           = var.project_id,
      central_nats_host    = var.wadm_nats_host,
      wasmcloud_creds_path = local.wasmcloud_nats_creds_path,
      wasmcloud_creds_name = local.wasmcloud_nats_creds_name,
    }
  )
}

resource "google_secret_manager_secret" "wasmcloud_cr_nats_config" {
  secret_id = "wasmcloud-cr-nats-config"
  project   = var.project_id
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "wasmcloud_nats_config_version" {
  secret      = google_secret_manager_secret.wasmcloud_cr_nats_config.id
  secret_data = local.nats_config
}


### Secrets IAM

locals {
  wasmcloud_secrets = {
    "wasmcloud_cr_nats_creds" = google_secret_manager_secret.wasmcloud_cr_nats_creds.id,
    "wadm_cr_nats_creds"      = google_secret_manager_secret.wadm_cr_nats_creds.id,
  }

  wadm_secrets = {
    "wadm_cr_nats_creds" = google_secret_manager_secret.wadm_cr_nats_creds.id,
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

### Services

resource "google_cloud_run_v2_service" "wasmcloud_v2_service" {
  name                = "wasmcloud"
  location            = var.region
  project             = var.project_id
  deletion_protection = false


  template {
    service_account = google_service_account.wasmcloud_service_sa.email

    volumes {
      name = "wasmcloud-nats-credentials"
      secret {
        secret       = google_secret_manager_secret.wasmcloud_cr_nats_creds.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.wasmcloud_nats_creds_name
        }
      }
    }

    volumes {
      name = "wadm-nats-credentials"
      secret {
        secret       = google_secret_manager_secret.wadm_cr_nats_creds.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.wadm_nats_creds_name
        }
      }
    }

    containers {
      name  = "hello"
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
      ports {
        container_port = 8080
      }
    }

    containers {
      name  = "wasmcloud"
      image = "wasmcloud/wasmcloud:1.3.1"

      resources {
        limits = {
          cpu    = "2"
          memory = "2048Mi"
        }
      }

      env {
        name  = "RUST_LOG"
        value = "trace,hyper=info,async_nats=info,oci_distribution=info,cranelift_codegen=warn"
      }
      env {
        name  = "WASMCLOUD_RPC_HOST"
        value = var.wasmcloud_nats_host
      }
      env {
        name  = "WASMCLOUD_RPC_PORT"
        value = var.wasmcloud_nats_port
      }
      env {
        name  = "WASMCLOUD_RPC_TLS"
        value = "true"
      }
      env {
        name  = "WASMCLOUD_CTL_HOST"
        value = var.wadm_nats_host
      }
      env {
        name  = "WASMCLOUD_CTL_PORT"
        value = var.wadm_nats_port
      }
      env {
        name  = "WASMCLOUD_CTL_TLS"
        value = "true"
      }
      env {
        name  = "WASMCLOUD_RPC_CREDS"
        value = "${local.wasmcloud_nats_creds_path}/${local.wasmcloud_nats_creds_name}"
      }
      env {
        name  = "WASMCLOUD_CTL_CREDS"
        value = "${local.wadm_nats_creds_path}/${local.wadm_nats_creds_name}"
      }
      env {
        name  = "WASMCLOUD_LOG_LEVEL"
        value = "debug"
      }
      env {
        name  = "WASMCLOUD_ALLOW_FILE_LOAD"
        value = "true"
      }
      env {
        name  = "WASMCLOUD_OBSERVABILITY_ENABLED"
        value = "false"
      }

      volume_mounts {
        name       = "wasmcloud-nats-credentials"
        mount_path = local.wasmcloud_nats_creds_path
      }

      volume_mounts {
        name       = "wadm-nats-credentials"
        mount_path = local.wadm_nats_creds_path
      }
    }
  }
}

resource "google_cloud_run_v2_service" "wadm_v2_service" {
  name                = "wadm"
  location            = var.region
  project             = var.project_id
  deletion_protection = false

  template {
    service_account = google_service_account.wadm_service_sa.email

    volumes {
      name = "wadm-nats-credentials"
      secret {
        secret       = google_secret_manager_secret.wadm_cr_nats_creds.id
        default_mode = 292 # 0444
        items {
          version = "latest"
          path    = local.wadm_nats_creds_name
        }
      }
    }

    containers {
      name  = "hello"
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }


      ports {
        container_port = 8080
      }
    }

    containers {
      name  = "wadm"
      image = "europe-north1-docker.pkg.dev/artifacts-352708/ghcr-test/wasmcloud/wadm:v0.17.1"
      resources {
        limits = {
          cpu    = "2"
          memory = "2048Mi"
        }
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
        value = "false"
      }

      volume_mounts {
        name       = "wadm-nats-credentials"
        mount_path = local.wadm_nats_creds_path
      }
    }

  }
}
