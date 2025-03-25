#!/usr/bin/env bash

# Default regions for replication
DEFAULT_REGIONS=("europe-north1" "europe-north2")
SECRET_REGIONS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --region)
      SECRET_REGIONS+=("$2")
      shift 2
      ;;
    *)
      PROJECT_ID="$1"
      shift
      ;;
  esac
done

# Validate PROJECT_ID
if [ -z "$PROJECT_ID" ]; then
  echo "Usage: $0 [--region <region>]... <project_id>"
  exit 1
fi

# Fallback to default regions if none provided
if [ ${#SECRET_REGIONS[@]} -eq 0 ]; then
  SECRET_REGIONS=("${DEFAULT_REGIONS[@]}")
  echo "No regions specified. Using defaults: ${SECRET_REGIONS[*]}"
else
  echo "Secrets will be replicated to regions: ${SECRET_REGIONS[*]}"
fi

# Construct --locations flags
LOCATIONS_ARGS=()
for region in "${SECRET_REGIONS[@]}"; do
  LOCATIONS_ARGS+=(--locations "$region")
done

# Secret names
TRANSIT_PUBLIC_KEY_SECRET="nats-kv-secrets-transit-public-key"
TRANSIT_SEED_KEY_SECRET="nats-kv-secrets-transit-seed-key"
ENCRYPTION_PUBLIC_KEY_SECRET="nats-kv-secrets-encryption-public-key"
ENCRYPTION_SEED_KEY_SECRET="nats-kv-secrets-encryption-seed-key"

# Function to check if a secret exists
secret_exists() {
  local secret_name=$1
  gcloud secrets describe "$secret_name" --project "$PROJECT_ID" > /dev/null 2>&1
}

# Temporary directory
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Extract keys from JSON
extract_keys_from_json() {
  local json_file=$1
  local key_type=$2
  jq -r ".$key_type" "$json_file"
}

# Generate keys
wash keys gen curve --output json > "$TEMP_DIR/transit.json"
TRANSIT_PUBLIC_KEY=$(extract_keys_from_json "$TEMP_DIR/transit.json" "public_key")
TRANSIT_SEED_KEY=$(extract_keys_from_json "$TEMP_DIR/transit.json" "seed")

wash keys gen curve --output json > "$TEMP_DIR/encryption.json"
ENCRYPTION_PUBLIC_KEY=$(extract_keys_from_json "$TEMP_DIR/encryption.json" "public_key")
ENCRYPTION_SEED_KEY=$(extract_keys_from_json "$TEMP_DIR/encryption.json" "seed")

echo "Checking and storing secrets in Google Cloud Secret Manager with user-managed replication policy..."

# Create a secret if it doesn't exist
create_secret_if_missing() {
  local secret_name=$1
  local secret_value=$2
  if secret_exists "$secret_name"; then
    echo "Secret $secret_name already exists. Skipping."
  else
    echo -n "$secret_value" | gcloud secrets create "$secret_name" \
      --project "$PROJECT_ID" \
      --replication-policy user-managed \
      "${LOCATIONS_ARGS[@]}" \
      --data-file=-
  fi
}

create_secret_if_missing "$TRANSIT_PUBLIC_KEY_SECRET" "$TRANSIT_PUBLIC_KEY"
create_secret_if_missing "$TRANSIT_SEED_KEY_SECRET" "$TRANSIT_SEED_KEY"
create_secret_if_missing "$ENCRYPTION_PUBLIC_KEY_SECRET" "$ENCRYPTION_PUBLIC_KEY"
create_secret_if_missing "$ENCRYPTION_SEED_KEY_SECRET" "$ENCRYPTION_SEED_KEY"

rm -rf "$TEMP_DIR"
echo "Temporary files cleaned up."

echo "Secrets created successfully (if they didn't already exist):" 
echo "- $TRANSIT_PUBLIC_KEY_SECRET"
echo "- $TRANSIT_SEED_KEY_SECRET"
echo "- $ENCRYPTION_PUBLIC_KEY_SECRET"
echo "- $ENCRYPTION_SEED_KEY_SECRET"
