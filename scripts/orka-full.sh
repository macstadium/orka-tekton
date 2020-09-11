#!/bin/sh
set -e

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
  set +x
  curl $CURL_FLAGS --request DELETE "${ORKA_API}/resources/vm/purge" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $TOKEN" \
    --data-raw "{
      \"orka_vm_name\": \"${VM_NAME}\"
    }"
  echo -e "\nPurged VM $VM_NAME"

  curl $CURL_FLAGS --request DELETE "${ORKA_API}/token" \
    --header "Authorization: Bearer $TOKEN"
  echo -e "\nDone."
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
echo -e "\nSuccessfully created VM config"
echo $VM_NAME | tee /tekton/results/vm-name

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

# Set SSH flags
SSH_FLAGS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10'
TIMEOUT=10
if [ "$SSH_KEY" = "true" ]; then
  SSHPASS=""
  SSH_FLAGS="-i $SSH_PASSFILE $SSH_FLAGS"
else
  SSHPASS="sshpass -f $SSH_PASSFILE"
fi
if [ "$VERBOSE" = "true" ]; then
  RSYNC_FLAGS='-av --progress'
  set -x
else
  SSH_FLAGS="$SSH_FLAGS -o LogLevel=ERROR"
  RSYNC_FLAGS='-a'
fi

# Wait for SSH access
set +e
while :; do
  echo "Waiting for ssh access ..."
  $SSHPASS ssh $SSH_FLAGS -p $SSH_PORT ${SSH_USERNAME}@${VM_IP} echo ok
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
  sleep 7
done
set -e

# Get name of build script
BUILD_SCRIPT=$(cat /tekton/results/build-script | head -1)

# Run build script
function build() {
  $SSHPASS ssh $SSH_FLAGS -p $SSH_PORT ${SSH_USERNAME}@${VM_IP} "cd ~/workspace/orka && ~/workspace/${BUILD_SCRIPT}"
}

# Copy build
echo "Running script in VM ..."
if [ "$COPY_BUILD" = "true" ]; then
  $SSHPASS rsync $RSYNC_FLAGS -e "ssh $SSH_FLAGS -p $SSH_PORT" /workspace ${SSH_USERNAME}@${VM_IP}:~
  build
  $SSHPASS rsync $RSYNC_FLAGS -e "ssh $SSH_FLAGS -p $SSH_PORT" ${SSH_USERNAME}@${VM_IP}:~/workspace/orka /workspace
else
  $SSHPASS scp $SSH_FLAGS -P $SSH_PORT -r /workspace ${SSH_USERNAME}@${VM_IP}:~
  build
fi
# sshpass -p $SSH_PASSFILE scp $SSH_FLAGS -P $SSH_PORT -r /workspace ${SSH_USERNAME}@${VM_IP}:~
# sshpass -p $SSH_PASSFILE ssh $SSH_FLAGS -p $SSH_PORT ${SSH_USERNAME}@${VM_IP} "cd ~/workspace/orka && ~/workspace/${BUILD_SCRIPT}"
# sshpass -p $SSH_PASSFILE scp $SSH_FLAGS -P $SSH_PORT -r ${SSH_USERNAME}@${VM_IP}:~/workspace/orka /workspace
