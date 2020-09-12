#!/bin/sh
set -ex

CURL_FLAGS='--location --fail'

# Get token
TOKEN=$(curl $CURL_FLAGS --connect-timeout 10 --request POST "${ORKA_API}/token" \
  --header 'Content-Type: application/json' \
  --data-raw "{
    \"email\": \"$SVC_EMAIL\",
    \"password\": \"$SVC_PASSWORD\"
  }" \
  | jq -r '.token'
  )
if [ -z "$TOKEN" ]; then
  echo "Check Orka API endpoint: $ORKA_API" >&2
  exit 1
fi
echo "Successfully fetched token"

# trap orka-cleanup EXIT

echo -n $TOKEN > /etc/orka-token
chmod 400 /etc/orka-token

# Create VM config
VM_NAME="tekton-$(openssl rand -hex 4)"
curl $CURL_FLAGS --request POST "${ORKA_API}/resources/vm/create" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $TOKEN" \
  --data-raw "{
    \"orka_vm_name\": \"$VM_NAME\",
    \"orka_base_image\": \"$BASE_IMAGE\",
    \"orka_image\": \"$VM_NAME\",
    \"orka_cpu_core\": $CPU_COUNT,
    \"vcpu_count\": $VCPU_COUNT,
    \"vnc_console\": $VNC_CONSOLE
  }"
echo -e "\nSuccessfully created VM config"
echo -n $VM_NAME > /tekton/results/vm-name
