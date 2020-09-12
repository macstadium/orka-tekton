#!/bin/sh

CURL_FLAGS='--location'

if [ "$ORKA_INIT" = "true" ]; then
  TOKEN=$(cat /etc/orka-token)
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

curl $CURL_FLAGS --request DELETE "${ORKA_API}/token" \
  --header "Authorization: Bearer $TOKEN"
echo -e "\nDone."
