# Google Tekton integration for Orka

This is a WIP

## User Requirements

- Orka service account set up (email / password)
- License key
- Base image with SSH enabled
- Orka API endpoint
  - http://10.10.10.100
  - http://10.221.188.100

## Workflow

1. Get token
1. Create VM config
1. Deploy VM
    - Store IP / port in variables
1. Wait for SSH access
1. Copy build script
1. Execute build script
1. Copy build artifact
1. Purge VM
1. Revoke token
