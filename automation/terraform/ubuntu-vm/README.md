# Terraform - Proxmox Ubuntu VM Provisioning

This lab demonstrates Infrastructure as Code (IaC) by using Terraform to provision and manage an Ubuntu VM on Proxmox VE.

## Architecture

Terraform runs from `ops01` and communicates with the Proxmox API using the `bpg/proxmox` Terraform provider.

Flow:

```text
ops01
  |
  | Terraform
  v
Proxmox API
  |
  v
Ubuntu Cloud Image
  |
  v
Proxmox VM
  |
  +-- 2 vCPU
  +-- 2 GB RAM
  +-- 32 GB disk
  +-- VirtIO NIC on vmbr0
  +-- DHCP networking
  |
  v
Cloud-Init
  |
  +-- Creates labadmin user
  +-- Injects SSH public key
  +-- Configures VM password

Terraform Components
Provider
The bpg/proxmox provider allows Terraform to communicate with the Proxmox VE API and manage infrastructure resources.
Resources
Terraform manages:
- Ubuntu cloud image
- Proxmox virtual machine
- CPU and memory allocation
- VM disk
- Network interface
- Cloud-Init configuration
Variables
variables.tf defines the input variable used by the configuration.
The actual VM password is supplied through terraform.tfvars, which is excluded from Git.
Cloud-Init
Cloud-Init performs the initial guest operating system configuration, including:
- Creating the labadmin user
- Injecting the SSH public key
- Configuring DHCP networking
- Setting the VM password
Terraform Workflow
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
init
Initialises the Terraform working directory and downloads the required Proxmox provider.
plan
Compares the desired Terraform configuration with the current managed infrastructure and previews the proposed changes.
apply
Applies the approved infrastructure changes through the Proxmox API.
state
Terraform state records the relationship between the resources defined in Terraform and the actual infrastructure being managed.
State files are excluded from Git because they may contain infrastructure and sensitive information.
IaC Change Test
After initially provisioning the VM, the Cloud-Init password configuration was changed through Terraform.
The workflow was:
Update desired configuration
        |
terraform plan
        |
Review proposed change
        |
terraform apply
        |
Proxmox configuration updated
This demonstrated Terraform reconciliation: infrastructure changes were made through code rather than manual configuration in the Proxmox GUI.
Terraform vs Ansible
In this lab the tools have different responsibilities:
- Terraform - provisions infrastructure
- Ansible - configures operating systems and services after infrastructure exists
Ansible was separately used in the wider lab to configure an Ubuntu VM and join it to the DC-B K3s cluster as a worker node.
Security
The following are deliberately excluded from source control:
- terraform.tfvars
- Terraform state files
- .terraform/
- API credentials
The Proxmox API token is supplied through an environment variable rather than being hardcoded into the Terraform configuration.
