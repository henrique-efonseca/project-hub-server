#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Log file
LOG_FILE="./logs/cleanup.log"
mkdir -p ./logs

# Server configuration
SERVER_USER="ubuntu"
SERVER_IP="ec2-51-20-8-80.eu-north-1.compute.amazonaws.com"
SSH_KEY_PATH="../ssh/project-hub-server-ssh.pem"

# Function to log messages with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')]: $1" | tee -a "$LOG_FILE"
}

# Function to execute SSH commands and log errors
ssh_command() {
    log "Executing SSH command: $1"
    OUTPUT=$(ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_IP" "$1" 2>&1) || {
        log "Error executing SSH command: $1"
        log "Output: $OUTPUT"
        exit 1
    }
    echo "$OUTPUT" | tee -a "$LOG_FILE"
}

# Log the start of the cleanup
log "Starting cleanup"

# Clean up old kernels on the remote server
log "Cleaning up old kernels on the server..."
ssh_command "
CURRENT_KERNEL=\$(uname -r)
LATEST_KERNEL=\$(dpkg --list 'linux-image*' | grep ^ii | awk '{print \$2}' | sort -V | tail -n 2)
for KERNEL in \$(dpkg --list 'linux-image*' | grep ^ii | awk '{print \$2}' | grep -vE \"(\${CURRENT_KERNEL}|\$(echo \${LATEST_KERNEL} | awk '{print \$2}'))\"); do
  echo \"Removing \$KERNEL\"
  sudo apt-get remove --purge -y \$KERNEL || { echo 'Error removing kernel \$KERNEL'; exit 1; }
done
sudo apt-get autoremove -y
" || {
    log "Error during kernel cleanup"
    exit 1
}

# Clean up package cache and unused dependencies
log "Cleaning up package cache and unused dependencies..."
ssh_command "sudo apt-get clean" || {
    log "Error during package cache cleanup"
    exit 1
}
ssh_command "sudo apt-get autoremove -y" || {
    log "Error during unused dependencies cleanup"
    exit 1
}

# Stop all running Docker containers
log "Stopping Docker containers on the server..."
ssh_command "sudo docker stop \$(sudo docker ps -q) || true" || {
    log "Error stopping Docker containers"
    exit 1
}

# Remove any existing Docker containers and images
log "Removing existing Docker containers and images on the server..."
ssh_command "sudo docker rm -f \$(sudo docker ps -a -q) || true" || {
    log "Error removing Docker containers"
    exit 1
}
ssh_command "sudo docker rmi -f \$(sudo docker images -q) || true" || {
    log "Error removing Docker images"
    exit 1
}

# Clean up unused Docker resources
log "Cleaning up unused Docker resources on the server..."
ssh_command "sudo docker system prune -a -f" || {
    log "Error cleaning up Docker resources"
    exit 1
}

# Check disk usage after cleanup
log "Disk usage after cleanup:"
ssh_command "df -h" || {
    log "Error checking disk usage"
    exit 1
}

# Cleanup completed successfully
log "Cleanup completed successfully"

# Cleanup time
log "Cleanup time: $(($(date +%s) - $(date +%s -r "$LOG_FILE"))) seconds"

# Exit successfully
exit 0
