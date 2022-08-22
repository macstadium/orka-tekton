#!/bin/sh

CURL_FLAGS='--location'

if [ -f "/etc/orka-token" ]; then
  TOKEN=$(cat /etc/orka-token | head -1)
fi

if [ -f "/etc/orka-vm-name" ]; then
  VM_NAME=$(cat /etc/orka-vm-name | head -1)
fi

if [ -n "$VM_NAME" ]; then
  curl $CURL_FLAGS --request DELETE "${ORKA_API}/resources/vm/purge" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $TOKEN" \
    --data-raw "{
      \"orka_vm_name\": \"${VM_NAME}\"
    }"
  echo -e "\nPurged VM $VM_NAME"
fi

if [ -n "$TOKEN" ]; then
  api_version=$(curl -s $CURL_FLAGS --request GET "${ORKA_API}/health-check" | jq ".api_version" | sed 's/[\.\"]//g')

  if [ $api_version -lt 210 ]; then
    curl $CURL_FLAGS --request DELETE "${ORKA_API}/token" \
      --header "Authorization: Bearer $TOKEN"
    echo -e "\nDone."
  fi 
fi
