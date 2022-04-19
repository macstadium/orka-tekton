#!/bin/sh
set -e

CURL_FLAGS='--location --fail'

REQUEST_DATA="\"orka_vm_name\": \"$VM_NAME\",
    \"gpu_passthrough\": $GPU_PASSTHROUGH"

# Add system_serial if passed
if [ -n "$SYSTEM_SERIAL" ]; then
  REQUEST_DATA="$REQUEST_DATA, \"system_serial\": \"$SYSTEM_SERIAL\""
fi

# Add vm_metadata if passed
if [ -n "$VM_METADATA" ]; then
  VM_METADATA_JSON="{\"items\": $VM_METADATA}"
  REQUEST_DATA="$REQUEST_DATA,
    \"vm_metadata\": $VM_METADATA_JSON"
fi

# Deploy VM
VM_DETAILS=$(curl $CURL_FLAGS --request POST "${ORKA_API}/resources/vm/deploy" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $TOKEN" \
  --data-raw "{$REQUEST_DATA}"
  )
echo $VM_DETAILS

# Extract SSH port and VM ip from response
VM_IP=$(echo $VM_DETAILS | jq -r '.ip')
SSH_PORT=$(echo $VM_DETAILS | jq -r '.ssh_port')

function delete_vm() {
  set +x
  curl $CURL_FLAGS --request DELETE "${ORKA_API}/resources/vm/delete" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $TOKEN" \
    --data-raw "{
      \"orka_vm_name\": \"${VM_ID}\"
    }"
  echo -e "\nDeleted VM $VM_ID"
}

if [ "$DELETE_VM" = "true" ]; then
  # Get VM ID and delete VM by ID on exit
  VM_ID=$(echo $VM_DETAILS | jq -r '.vm_id')
  trap delete_vm EXIT
fi

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
BUILD_SCRIPT=build-script

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
