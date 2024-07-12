#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Log file
LOG_FILE="./logs/deployment.log"
mkdir -p ./logs

# Variables
SERVER_USER="ubuntu"
SERVER_IP="ec2-51-20-8-80.eu-north-1.compute.amazonaws.com"
SSH_KEY_PATH="../ssh/project-hub-server-ssh.pem"
PROJECT_CONFIG_FILE="projectsConfigs.ts"

# Load project configurations from projectsConfigs.ts
PROJECT_CONFIGS=$(sed -n '/export const PROJECTS_CONFIGS = \[/,/];/p' "$PROJECT_CONFIG_FILE" | sed '1d;$d')

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

# Function to execute local commands and log errors
local_command() {
    log "Executing local command: $@"
    OUTPUT=$("$@" 2>&1) || {
        log "Error executing local command: $@"
        log "Output: $OUTPUT"
        exit 1
    }
    echo "$OUTPUT" | tee -a "$LOG_FILE"
}

# Function to check if a path exists
check_path() {
    if [ ! -e "$1" ]; then
        log "Error: Path $1 does not exist."
        exit 1
    fi
}

# Log the start of the deployment
log "Starting deployment"

# Stop all running Docker containers
log "Stopping Docker containers on the server..."
ssh_command "sudo docker stop \$(sudo docker ps -q) || true"

# Remove any existing Docker containers and images
log "Removing existing Docker containers and images on the server..."
ssh_command "sudo docker rm -f \$(sudo docker ps -a -q) || true"
ssh_command "sudo docker rmi -f \$(sudo docker images -q) || true"

# Parse project configurations and perform operations
echo "$PROJECT_CONFIGS" | jq -c '.[]' | while IFS= read -r row; do
    PROJECT=$(echo "$row" | jq -r '.project')
    LOCAL_PATH=$(echo "$row" | jq -r '.localPath')
    REMOTE_PATH=$(echo "$row" | jq -r '.remotePath')

    # Check if local paths exist
    check_path "$LOCAL_PATH"

    # Remove existing project directory on the server
    log "Removing directory /home/ubuntu/$PROJECT on the server..."
    ssh_command "sudo rm -rf /home/ubuntu/$PROJECT"

    # Clone the repository again
    REPO="https://github.com/henrique-efonseca/$PROJECT.git"
    log "Cloning repository $REPO on the server..."
    ssh_command "git clone $REPO /home/ubuntu/$PROJECT"

    # Copy local files to remote server
    log "Copying files for $PROJECT to the server..."
    local_command scp -i "$SSH_KEY_PATH" -r "$LOCAL_PATH" "$SERVER_USER@$SERVER_IP:$REMOTE_PATH"
done

# Create and start the Docker network
log "Creating and starting the Docker network on the server..."
ssh_command "sudo docker network create project_hub_network || true"

# Build and start Docker containers for each project
echo "$PROJECT_CONFIGS" | jq -c '.[]' | while IFS= read -r row; do
    PROJECT=$(echo "$row" | jq -r '.project')

    log "Building and starting Docker services containers for $PROJECT on the server..."
    ssh_command "cd /home/ubuntu/$PROJECT/docker && sudo docker compose up --build -d"
done

# Wait 60 seconds for the containers to start
log "Waiting 60 seconds for the service containers to start..."
sleep 60

# Check the status of the Docker containers
log "Checking the status of the Docker containers on the server..."
ssh_command "sudo docker ps"

# Deployment completed successfully
log "Deployment completed successfully"

# Deployment time
log "Deployment time: $(($(date +%s) - $(date +%s -r "$LOG_FILE"))) seconds"

# Exit successfully
exit 0
