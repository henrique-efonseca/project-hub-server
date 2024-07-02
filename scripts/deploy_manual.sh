#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Log file
LOG_FILE="./logs/deployment.log"
mkdir -p ./logs

# Variables
SERVER_USER="ubuntu"
SERVER_IP="ec2-13-53-42-166.eu-north-1.compute.amazonaws.com"
SSH_KEY_PATH="../ssh/project-hub-server-ssh.pem"
PROJECTS=("project-hub-server" "personal-blog" "personal-website")
LOCAL_CERTS_PATH="../reverse-proxy/certs"
REMOTE_CERTS_PATH="/home/ubuntu/project-hub-server/reverse-proxy"
LOCAL_CONFIG_PATH="../../personal-blog/config"
REMOTE_CONFIG_PATH="/home/ubuntu/personal-blog"
GIT_REPOS=("https://github.com/henrique-efonseca/personal-blog.git" "https://github.com/henrique-efonseca/personal-website.git" "https://github.com/henrique-efonseca/project-hub-server.git")

# Function to execute SSH commands and log errors
ssh_command() {
    OUTPUT=$(ssh -i "$SSH_KEY_PATH" "$SERVER_USER@$SERVER_IP" "$1" 2>&1) || {
        echo "Error executing SSH command: $1" | tee -a "$LOG_FILE"
        echo "Output: $OUTPUT" | tee -a "$LOG_FILE"
        exit 1
    }
    echo "$OUTPUT" | tee -a "$LOG_FILE"
}

# Function to execute local commands and log errors
local_command() {
    OUTPUT=$("$@" 2>&1) || {
        echo "Error executing local command: $@" | tee -a "$LOG_FILE"
        echo "Output: $OUTPUT" | tee -a "$LOG_FILE"
        exit 1
    }
    echo "$OUTPUT" | tee -a "$LOG_FILE"
}

# Function to check if a path exists
check_path() {
    if [ ! -e "$1" ]; then
        echo "Error: Path $1 does not exist." | tee -a "$LOG_FILE"
        exit 1
    fi
}

# Check if all necessary paths exist
check_path "$SSH_KEY_PATH"
check_path "$LOCAL_CERTS_PATH"
check_path "$LOCAL_CONFIG_PATH"

# Log the start of the deployment
echo "Starting deployment at $(date)" | tee -a "$LOG_FILE"

# Stop all running Docker containers
echo "Stopping Docker containers on the server..." | tee -a "$LOG_FILE"
ssh_command "sudo docker stop \$(sudo docker ps -q) || true"

# Remove any existing Docker containers and images
echo "Removing existing Docker containers and images on the server..." | tee -a "$LOG_FILE"
ssh_command "sudo docker rm -f \$(sudo docker ps -a -q) || true"
ssh_command "sudo docker rmi -f \$(sudo docker images -q) || true"

# Connect to server and remove directories
for PROJECT in "${PROJECTS[@]}"; do
    echo "Removing directory /home/ubuntu/$PROJECT on the server..." | tee -a "$LOG_FILE"
    ssh_command "rm -rf /home/ubuntu/$PROJECT"
done

# Clone the repositories again
for REPO in "${GIT_REPOS[@]}"; do
    PROJECT_NAME=$(basename "$REPO" .git)
    echo "Cloning repository $REPO on the server..." | tee -a "$LOG_FILE"
    ssh_command "git clone $REPO /home/ubuntu/$PROJECT_NAME"
done

# Copy certificates and config files
echo "Copying certificates to the server..." | tee -a "$LOG_FILE"
local_command scp -i "$SSH_KEY_PATH" -r "$LOCAL_CERTS_PATH" "$SERVER_USER@$SERVER_IP:$REMOTE_CERTS_PATH"

echo "Copying config files to the server..." | tee -a "$LOG_FILE"
local_command scp -i "$SSH_KEY_PATH" -r "$LOCAL_CONFIG_PATH" "$SERVER_USER@$SERVER_IP:$REMOTE_CONFIG_PATH"

# Build and start Docker containers
echo "Building and starting Docker services containers on the server..." | tee -a "$LOG_FILE"
ssh_command "cd /home/ubuntu/personal-website/docker && sudo docker compose -p personal-website up --build -d"
echo 
ssh_command "cd /home/ubuntu/personal-blog/docker && sudo docker compose -p personal-blog up --build -d"

# Wait 60 seconds for the containers to start
echo "Waiting 60 seconds for the service containers to start..." | tee -a "$LOG_FILE"
sleep 60

# Build and start the reverse proxy Docker container
echo "Building and starting the reverse proxy Docker container on the server..." | tee -a "$LOG_FILE"
ssh_command "cd /home/ubuntu/project-hub-server/reverse-proxy/docker && sudo docker compose -p reverse-proxy up --build -d"

# Check the status of the Docker containers
echo "Checking the status of the Docker containers on the server..." | tee -a "$LOG_FILE"
ssh_command "sudo docker ps"

# Deployment completed successfully
echo "Deployment completed successfully at $(date)" | tee -a "$LOG_FILE"

# Exit successfully
exit 0
