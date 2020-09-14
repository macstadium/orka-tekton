#!/bin/sh
set -e

trap orka-cleanup EXIT

orka-init

export TOKEN=$(cat /etc/orka-token | head -1)
export VM_NAME=$(cat /etc/orka-vm-name | head -1)

orka-deploy
