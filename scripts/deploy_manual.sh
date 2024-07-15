    #!/bin/bash

    # Exit immediately if a command exits with a non-zero status
    set -e

    # Log file
    LOG_FILE="./logs/deployment.log"
    mkdir -p ./logs

    # Server Configuration
    SERVER_USER="ubuntu"
    SERVER_IP="ec2-51-20-8-80.eu-north-1.compute.amazonaws.com"
    # SSH key path
    SSH_KEY_PATH="../ssh/project-hub-server-ssh.pem"
    # Projects to deploy
    PROJECTS=("project-hub-server" "henriquefonseca.me")
    GIT_REPOS=("https://github.com/henrique-efonseca/project-hub-server.git" "https://github.com/henrique-efonseca/henriquefonseca.me.git" )
    # Local and remote paths for certificates and config files
    LOCAL_CERTS_PATH="../reverse-proxy/certs"
    # Remote path for certificates
    REMOTE_CERTS_PATH="/home/ubuntu/project-hub-server/reverse-proxy"
    #`Local and remote paths for config files`
    LOCAL_CONFIG_PATH="../../henriquefonseca.me/.env.local"
    REMOTE_CONFIG_PATH="/home/ubuntu/henriquefonseca.me"


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

    # Check if all necessary paths exist
    check_path "$SSH_KEY_PATH"
    check_path "$LOCAL_CERTS_PATH"
    check_path "$LOCAL_CONFIG_PATH"

    # Log the start of the deployment
    log "Starting deployment"

    # Stop all running Docker containers
    log "Stopping Docker containers on the server..."
    ssh_command "sudo docker stop \$(sudo docker ps -q) || true"

    # Remove any existing Docker containers and images
    log "Removing existing Docker containers and images on the server..."
    ssh_command "sudo docker rm -f \$(sudo docker ps -a -q) || true"
    ssh_command "sudo docker rmi -f \$(sudo docker images -q) || true"

    # Connect to server and remove directories
    for PROJECT in "${PROJECTS[@]}"; do
        log "Removing directory /home/ubuntu/$PROJECT on the server..."
        ssh_command "sudo rm -rf /home/ubuntu/$PROJECT"
    done

    # Clone the repositories again
    for REPO in "${GIT_REPOS[@]}"; do
        PROJECT_NAME=$(basename "$REPO" .git)
        log "Cloning repository $REPO on the server..."
        ssh_command "git clone $REPO /home/ubuntu/$PROJECT_NAME"
    done

    # Copy certificates and config files
    log "Copying certificates to the server..."
    local_command scp -i "$SSH_KEY_PATH" -r "$LOCAL_CERTS_PATH" "$SERVER_USER@$SERVER_IP:$REMOTE_CERTS_PATH"

    log "Copying config files to the server..."
    local_command scp -i "$SSH_KEY_PATH" -r "$LOCAL_CONFIG_PATH" "$SERVER_USER@$SERVER_IP:$REMOTE_CONFIG_PATH"

    # Create and start the Docker network
    log "Creating and starting the Docker network on the server..."
    ssh_command "sudo docker network create project_hub_network || true"

    # Build and start Docker containers
    log "Building and starting Docker services containers on the server..."
    ssh_command "cd /home/ubuntu/henriquefonseca.me/docker && sudo docker compose -p henriquefonseca up --build -d"

    # Wait 60 seconds for the containers to start
    log "Waiting 60 seconds for the service containers to start..."
    sleep 60

    # Build and start the reverse proxy Docker container
    log "Building and starting the reverse proxy Docker container on the server..."
    ssh_command "cd /home/ubuntu/project-hub-server/reverse-proxy/docker && sudo docker compose -p reverse-proxy up --build -d"

    # Check the status of the Docker containers
    log "Checking the status of the Docker containers on the server..."
    ssh_command "sudo docker ps"

    # Deployment completed successfully
    log "Deployment completed successfully"

    # Deployment time
    log "Deployment time: $(($(date +%s) - $(date +%s -r "$LOG_FILE"))) seconds"

    # Exit successfully
    exit 0