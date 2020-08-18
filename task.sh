#!/bin/sh
set -ex

ORKA_API='http://10.10.10.100'
LICENSE_KEY='orka-license-key'
BASE_IMAGE='catalina-ssh-30G.img'

FLAGS='--location --fail'

# Get token
TOKEN=$(curl $FLAGS --request POST "${ORKA_API}/token" \
  --header 'Content-Type: application/json' \
  --data-raw '{
    "email": "tekton-svc@macstadium.com",
    "password": "p@ssw0rd"
  }' \
  | jq -r '.token'
  )

function cleanup()
{
  curl $FLAGS --request DELETE "${ORKA_API}/resources/vm/purge" \
    --header 'Content-Type: application/json' \
    --header "Authorization: Bearer $TOKEN" \
    --data-raw "{
      \"orka_vm_name\": \"${VM_NAME}\"
    }"
  echo

  curl $FLAGS --request DELETE "${ORKA_API}/token" \
    --header "Authorization: Bearer $TOKEN"
  echo "\nDone."
}

trap cleanup EXIT

# Create VM config
VM_NAME="tekton-$(openssl rand -hex 4)"
curl $FLAGS --request POST "${ORKA_API}/resources/vm/create" \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $TOKEN" \
  --data-raw "$(cat <<EOF
{
  "orka_vm_name": "$VM_NAME",
  "orka_base_image": "$BASE_IMAGE",
  "orka_image": "$VM_NAME",
  "orka_cpu_core": 6,
  "vcpu_count": 6,
  "vnc_console": true
}
EOF
)"
echo

# Deploy VM
VM_DETAILS=$(curl $FLAGS --request POST "${ORKA_API}/resources/vm/deploy" \
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
  sshpass -p admin ssh $SSH_FLAGS -p $SSH_PORT admin@${VM_IP} echo ok
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
  sleep 5
done
set -e

SCRIPT=$(mktemp)
cat <<EOF > $SCRIPT
#!/bin/sh

set -ex

mkdir -p out
nvram -xp > out/nvram.xml
EOF

# Copy build
sshpass -p admin ssh $SSH_FLAGS -p $SSH_PORT admin@${VM_IP} "mkdir -p ~/workspace/${VM_NAME}"
sshpass -p admin scp $SSH_FLAGS -P $SSH_PORT $SCRIPT admin@${VM_IP}:~/workspace/${VM_NAME}/script.sh
sshpass -p admin ssh $SSH_FLAGS -p $SSH_PORT admin@${VM_IP} "cd ~/workspace/${VM_NAME} && sh script.sh && rm script.sh"
sshpass -p admin scp $SSH_FLAGS -P $SSH_PORT -r admin@${VM_IP}:~/workspace/${VM_NAME} .
