# DC-B and Azure Arc

## What was built

I created a second Kubernetes cluster to represent Data Centre B.

DC-B has three K3s nodes:

| Node           | IP            | Role          |
| dc-b-control01 | 192.168.1.200 | Control plane |
| dc-b-worker01 | 192.168.1.204 | Worker |
| dc-b-worker02 | 192.168.1.141 | Worker |

DC-B is completely separate from DC-A.

This means both sites now have their own Kubernetes cluster.

## Current setup

DC-A:
- 1 control-plane node
- 2 worker nodes
- Azure Arc connected

DC-B:
- 1 control-plane node
- 2 worker nodes
- Azure Arc connected

Both clusters can be managed from `ops01`.

## Managing both clusters from ops01

DC-A uses:

```text
Context: dc-a-direct

DC-B uses:

Context: dc-b-direct

I created aliases so it is easy to manage each cluster:

alias kda='kubectl --kubeconfig ~/.kube/config --context dc-a-direct'
alias kdb='kubectl --kubeconfig ~/.kube/dc-b.config --context dc-b-direct'

Usage:

kda get nodes
kdb get nodes

kda = DC-A

kdb = DC-B

## Azure authentication

Interactive Azure login on ops01 was being blocked by Microsoft Entra security settings.

I created a service principal called:

sp-tvms-ops01

This gives ops01 its own Azure identity for Azure CLI and automation.

The flow is:

ops01
  |
  v
sp-tvms-ops01
  |
  v
Microsoft Entra ID
  |
  v
Azure

The service principal has access to:

rg-tvms-hybrid-lab


## Azure Arc

DC-B was connected to Azure Arc as:

dc-b

Azure Arc now shows:

Azure Arc
├── dc-a
└── dc-b

Azure Arc does not move the clusters into Azure.

The Kubernetes clusters still run locally on Proxmox.

Azure Arc provides Azure-based management and visibility.
