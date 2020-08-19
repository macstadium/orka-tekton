#!/bin/sh
set -e

# ORKA_API='http://10.10.10.100'
# LICENSE_KEY='orka-license-key'
# BASE_IMAGE='catalina-ssh-30G.img'

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
  echo "Check Orka API endpoint: $ORKA_API"
  exit 1
fi
echo "Successfully fetched token"

function cleanup()
{
  curl $CURL_FLAGS --request DELETE "${ORKA_API}/resources/vm/purge" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $TOKEN" \
    --data-raw "{
      \"orka_vm_name\": \"${VM_NAME}\"
    }"
  echo

  curl $CURL_FLAGS --request DELETE "${ORKA_API}/token" \
    --header "Authorization: Bearer $TOKEN"
  echo "\nDone."
}

trap cleanup EXIT

# Create VM config
VM_NAME="tekton-$(openssl rand -hex 4)"
curl $CURL_FLAGS --request POST "${ORKA_API}/resources/vm/create" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $TOKEN" \
  --data-raw "{
    \"orka_vm_name\": \"$VM_NAME\",
    \"orka_base_image\": \"$BASE_IMAGE\",
    \"orka_image\": \"$VM_NAME\",
    \"orka_cpu_core\": 6,
    \"vcpu_count\": 6,
    \"vnc_console\": true
  }"
echo $VM_NAME | tee /tekton/results/vm-config

# Deploy VM
VM_DETAILS=$(curl $CURL_FLAGS --request POST "${ORKA_API}/resources/vm/deploy" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $TOKEN" \
  --data-raw "{
    \"orka_vm_name\": \"${VM_NAME}\"
  }"
  )
echo $VM_DETAILS

# Extract SSH port and VM id from response
VM_IP=$(echo $VM_DETAILS | jq -r '.ip')
SSH_PORT=$(echo $VM_DETAILS | jq -r '.ssh_port')

# Wait for SSH access
SSH_FLAGS='-o StrictHostKeyChecking=no -o ConnectTimeout=10 -o LogLevel=ERROR'
TIMEOUT=10
set +e
while :; do
  echo "Waiting for ssh access ..."
  sshpass -p $SSH_PASSWORD ssh $SSH_FLAGS -p $SSH_PORT ${SSH_USERNAME}@${VM_IP} echo ok
  RESULT=$?
  if [ $RESULT -eq 0 ]; then
    break
  elif [ $RESULT -eq 5 ]; then
    echo "Invalid VM username/password"
    exit 1
  fi
  TIMEOUT=$((TIMEOUT-1))
  if [ $TIMEOUT -eq 0 ]; then
    echo "Timed out waiting for ssh access"
    exit 1
  fi
  echo "$TIMEOUT retries remaining"
  sleep 5
done
set -e

# If script does not start with shebang, prepend it
SCRIPT=$(mktemp)
[[ ! $(head -c2 script.sh) == \#! ]] && cat > $SCRIPT << EOF
#!/bin/sh
set -ex
EOF
cat script.sh >> $SCRIPT && rm script.sh
chmod 755 $SCRIPT

# Copy build
echo "Running script in VM ..."
sshpass -p $SSH_PASSWORD ssh $SSH_FLAGS -p $SSH_PORT ${SSH_USERNAME}@${VM_IP} "mkdir -p ~/workspace/${VM_NAME}"
sshpass -p $SSH_PASSWORD scp $SSH_FLAGS -P $SSH_PORT $SCRIPT ${SSH_USERNAME}@${VM_IP}:~/workspace/${VM_NAME}/${VM_NAME}.sh
sshpass -p $SSH_PASSWORD ssh $SSH_FLAGS -p $SSH_PORT ${SSH_USERNAME}@${VM_IP} "cd ~/workspace/${VM_NAME} && ./${VM_NAME}.sh && rm ${VM_NAME}.sh"
sshpass -p $SSH_PASSWORD scp $SSH_FLAGS -P $SSH_PORT -r ${SSH_USERNAME}@${VM_IP}:~/workspace/${VM_NAME} .
