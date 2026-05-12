#!/usr/bin/env bash
set -euo pipefail

# Fail fast if required SSH key environment variables are missing
if [ -z "${SSH_PRIVATE_KEY:-}" ] || [ -z "${SSH_PUBLIC_KEY:-}" ]; then
    echo "ERROR: Both SSH_PRIVATE_KEY and SSH_PUBLIC_KEY environment variables must be provided."
    exit 3
fi

echo "Wiring up SSH keys from container env vars..."

# Create SSH directory for the runner user
SSH_DIR="/home/runner/.ssh"
mkdir -p "${SSH_DIR}"

# Write private key (id_rsa) - preserves newlines and formatting
printf '%s\n' "${SSH_PRIVATE_KEY}" > "${SSH_DIR}/id_rsa"

# Write public key (id_rsa.pub)
printf '%s\n' "${SSH_PUBLIC_KEY}" > "${SSH_DIR}/id_rsa.pub"

# Set strict, correct permissions (required by OpenSSH and the runners service)
chmod 700 "${SSH_DIR}"
chmod 600 "${SSH_DIR}/id_rsa"
chmod 644 "${SSH_DIR}/id_rsa.pub"

echo "SSH keys successfully wired up in ${SSH_DIR}/ (id_rsa + id_rsa.pub)"

# Forward all arguments to the original CLI and exec (replaces this process)
exec github-hetzner-runners "$@"
