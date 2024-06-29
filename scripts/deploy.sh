#!/bin/bash

# Load the .env file
set -a
[ -f .env ] && . .env
set +a

# Function to display usage
usage() {
  echo "Usage: $0 [blog|website|all]"
  exit 1
}

# Check if an argument is provided
if [ -z "$1" ]; then
  usage
fi

# Run the script to copy .env files
echo "Running script to copy .env files..."
bash $COPY_SCRIPT

# Check if the copy script was successful
if [ $? -ne 0 ]; then
  echo "Failed to copy .env files."
  exit 1
fi

# Determine which playbook to run based on the argument
case "$1" in
  blog)
    PLAYBOOK="$ANSIBLE_DIR/ansible/playbooks/deploy_blog.yml"
    ;;
  website)
    PLAYBOOK="$ANSIBLE_DIR/ansible/playbooks/deploy_website.yml"
    ;;
  all)
    PLAYBOOK="$ANSIBLE_DIR/ansible/playbooks/deploy_all.yml"
    ;;
  *)
    usage
    ;;
esac

# Run the Ansible playbook
echo "Running Ansible playbook for $1..."
ansible-playbook $PLAYBOOK

# Check if the Ansible playbook ran successfully
if [ $? -ne 0 ]; then
  echo "Failed to run Ansible playbook for $1."
  exit 1
fi

echo "Deployment of $1 completed successfully."
