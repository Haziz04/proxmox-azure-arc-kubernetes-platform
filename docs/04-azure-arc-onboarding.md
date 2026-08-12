##Objective
Connect an externally hosted K3s Kubernetes cluster to Azure Arc.

##Architecture
Proxmox → Ubuntu VMs → K3s → Azure Arc

##Implementation
- Azure CLI installed on ops01
- Authenticated ops01 to Azure
- "connectedk8s" extension installed
- Required Azure providers registered
- Resource Group created
- Existing K3s cluster connected to Azure Arc

##Validation
- dc-a visible in Azure
- azure-arc namespace present locally
- Arc agents Running
- Existing application workloads remain local

##Key learning
Azure Arc is the management/governance layer.
It does not convert Proxmox into Azure Local and does not move
my Kubernetes workloads into Azure.
