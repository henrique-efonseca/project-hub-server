# Project Hub Infrastructure

Terraform configuration and Ansible playbooks for provisioning and configuring the infrastructure of my Project Hub server, deploying services, and setting up the reverse proxy.

## Overview
I have a server, that I called **Project Hub**, to showcase some of my projects.
This repository contains Terraform scripts for provisioning the necessary infrastructure on AWS and Ansible playbooks for configuring and updating the server, deploying multiple services, and setting up a reverse proxy.
This setup ensures a consistent and automated deployment process for the Project Hub server.

## Features

- **Infrastructure as Code**: Use Terraform to define and provision server resources.
- **Configuration Management**: Use Ansible to automate server configuration and application deployment.
- **Reverse Proxy Setup**: Configure Apache to route requests to different services based on the URL.
- **Automation**: Ensure consistent and repeatable deployments with minimal manual intervention.

## Prerequisites

- Terraform installed locally
- Ansible installed locally
- An AWS account with appropriate permissions
- SSH key pair for accessing the server
- Basic knowledge of Terraform and Ansible

## Workflow Overview

1. **Provision the Server with Terraform**:
   - Run Terraform locally to provision the server and any necessary infrastructure (such as an EC2 instance on AWS).
   - This is typically done once initially or whenever there is a need to change the infrastructure itself (e.g., changing instance types, adding new resources).

2. **Configure and Deploy with Ansible**:
   - After the infrastructure is provisioned, use Ansible to configure the server, deploy services, and manage the reverse proxy.
   - Ansible can be run multiple times as needed to apply configuration changes, deploy new versions of services, or update existing configurations.

## Setup Instructions

### Initial Setup

1. **Clone the Repository**:
```bash
   git clone https://github.com/yourusername/project-hub-infrastructure.git
   cd project-hub-infrastructure
```
<br>


2. **Initialize Terraform**:
```bash

terraform init
```
<br>



3. **Apply Terraform Configuration**:

```bash
terraform apply
```

Follow the prompts to provide necessary variables such as the SSH key pair name.
<br>

4. **Run Ansible Playboo**:

This playbook configures the server, deploys the services, and sets up the reverse proxy.
```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml
```
<br>


### Updating Configuration or Services


1. **Modify Ansible Playbooks or Service Repositories**:

Make necessary changes to Ansible playbooks, roles in the ansible directory or services.
<br>


2. **Run Ansible Playbook**:

To apply any changes made to the Ansible playbooks, roles in the ansible directory, or any service repository (e.g., updating code or Dockerfile), it is necessary to run the Ansible playbook.
Apply the updates using Ansible:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml
```