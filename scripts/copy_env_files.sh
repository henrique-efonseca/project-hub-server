#!/bin/bash

# Define the paths
BASE_DIR="/path/to/github"
ANSIBLE_FILES_DIR="$BASE_DIR/project-hub-infrastructure/ansible/files"
BLOG_DIR="$BASE_DIR/blog"
WEBSITE_DIR="$BASE_DIR/website"

# Ensure the ansible files directory exists
mkdir -p $ANSIBLE_FILES_DIR

# Copy .env file from blog repository
if [ -f "$BLOG_DIR/.env" ]; then
  cp "$BLOG_DIR/.env" "$ANSIBLE_FILES_DIR/blog.env"
  echo "Copied .env from blog to $ANSIBLE_FILES_DIR/blog.env"
else
  echo "No .env file found in $BLOG_DIR"
fi

# Copy .env file from website repository
if [ -f "$WEBSITE_DIR/.env" ]; then
  cp "$WEBSITE_DIR/.env" "$ANSIBLE_FILES_DIR/website.env"
  echo "Copied .env from website to $ANSIBLE_FILES_DIR/website.env"
else
  echo "No .env file found in $WEBSITE_DIR"
fi
