terraform {
  required_version = ">= 1.9.5"
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = ">= 6.3.0, < 7.0"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 6.3.0, < 7.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "~> 2.0"
    }
  }
}
