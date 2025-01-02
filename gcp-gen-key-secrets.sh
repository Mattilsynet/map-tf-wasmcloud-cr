#!/usr/bin/env bash

# Default region for secrets
DEFAULT_REGION="europe-north1"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --region)
      SECRET_REGION="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      PROJECT_ID="$1"
      shift # past argument
      ;;
  esac
done

# Validate PROJECT_ID
if [ -z "$PROJECT_ID" ]; then
  echo "Usage: $0 [--region <region>] <project_id>"
  exit 1
fi

# Set region if not specified
if [ -z "$SECRET_REGION" ]; then
  SECRET_REGION="$DEFAULT_REGION"
  echo "Region not specified. Using default region: $SECRET_REGION."
else
  echo "Secrets will be created in region: $SECRET_REGION"
fi
REGION_FLAG="--locations=$SECRET_REGION"

# Set variables for the secret names
TRANSIT_PUBLIC_KEY_SECRET="nats-kv-secrets-transit-public-key"
TRANSIT_SEED_KEY_SECRET="nats-kv-secrets-transit-seed-key"
ENCRYPTION_PUBLIC_KEY_SECRET="nats-kv-secrets-encryption-public-key"
ENCRYPTION_SEED_KEY_SECRET="nats-kv-secrets-encryption-seed-key"

# Function to check if a secret exists
secret_exists() {
  local secret_name=$1
  gcloud secrets describe "$secret_name" --project "$PROJECT_ID" > /dev/null 2>&1
}

# Create a temporary directory for key generation
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Function to extract keys from JSON
extract_keys_from_json() {
  local json_file=$1
  local key_type=$2

  jq -r ".$key_type" "$json_file"
}

# Generate keys for transit
wash keys gen curve --output json > "$TEMP_DIR/transit.json"
TRANSIT_PUBLIC_KEY=$(extract_keys_from_json "$TEMP_DIR/transit.json" "public_key")
TRANSIT_SEED_KEY=$(extract_keys_from_json "$TEMP_DIR/transit.json" "seed")

# Generate keys for encryption
wash keys gen curve --output json > "$TEMP_DIR/encryption.json"
ENCRYPTION_PUBLIC_KEY=$(extract_keys_from_json "$TEMP_DIR/encryption.json" "public_key")
ENCRYPTION_SEED_KEY=$(extract_keys_from_json "$TEMP_DIR/encryption.json" "seed")

# Store the secrets in Google Cloud Secret Manager
echo "Checking and storing secrets in Google Cloud Secret Manager with user-managed replication policy..."

# Transit Public Key
if secret_exists "$TRANSIT_PUBLIC_KEY_SECRET"; then
  echo "Secret $TRANSIT_PUBLIC_KEY_SECRET already exists. Skipping creation."
else
  echo -n "$TRANSIT_PUBLIC_KEY" | gcloud secrets create $TRANSIT_PUBLIC_KEY_SECRET \
    --project "$PROJECT_ID" \
    --replication-policy user-managed \
    --locations "$SECRET_REGION" \
    --data-file=-
fi

# Transit Seed Key
if secret_exists "$TRANSIT_SEED_KEY_SECRET"; then
  echo "Secret $TRANSIT_SEED_KEY_SECRET already exists. Skipping creation."
else
  echo -n "$TRANSIT_SEED_KEY" | gcloud secrets create $TRANSIT_SEED_KEY_SECRET \
    --project "$PROJECT_ID" \
    --replication-policy user-managed \
    --locations "$SECRET_REGION" \
    --data-file=-
fi

# Encryption Public Key
if secret_exists "$ENCRYPTION_PUBLIC_KEY_SECRET"; then
  echo "Secret $ENCRYPTION_PUBLIC_KEY_SECRET already exists. Skipping creation."
else
  echo -n "$ENCRYPTION_PUBLIC_KEY" | gcloud secrets create $ENCRYPTION_PUBLIC_KEY_SECRET \
    --project "$PROJECT_ID" \
    --replication-policy user-managed \
    --locations "$SECRET_REGION" \
    --data-file=-
fi

# Encryption Seed Key
if secret_exists "$ENCRYPTION_SEED_KEY_SECRET"; then
  echo "Secret $ENCRYPTION_SEED_KEY_SECRET already exists. Skipping creation."
else
  echo -n "$ENCRYPTION_SEED_KEY" | gcloud secrets create $ENCRYPTION_SEED_KEY_SECRET \
    --project "$PROJECT_ID" \
    --replication-policy user-managed \
    --locations "$SECRET_REGION" \
    --data-file=-
fi

# Clean up temporary files
rm -rf $TEMP_DIR
echo "Temporary files cleaned up."

echo "Secrets created successfully (if they didn't already exist):" 
echo "- $TRANSIT_PUBLIC_KEY_SECRET"
echo "- $TRANSIT_SEED_KEY_SECRET"
echo "- $ENCRYPTION_PUBLIC_KEY_SECRET"
echo "- $ENCRYPTION_SEED_KEY_SECRET"

