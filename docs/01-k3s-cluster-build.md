# Three-Node K3s Kubernetes Cluster

## Objective

Build a Kubernetes cluster using K3s on Ubuntu virtual machines hosted
by Proxmox VE.

## Architecture

- `k8s-control01` — K3s server and Kubernetes control plane
- `k8s-worker01` — K3s agent and worker node
- `k8s-worker02` — K3s agent and worker node
- `ops01` — Management workstation

## Completed work

1. Installed the K3s server on `k8s-control01`.
2. Verified the Kubernetes API and system Pods.
3. Joined `k8s-worker01` to the cluster.
4. Joined `k8s-worker02` to the cluster.
5. Confirmed all three nodes reported `Ready`.

## Components

The K3s installation includes:

- Kubernetes API server
- Scheduler and controllers
- Kubelet
- Containerd runtime
- CoreDNS
- Metrics Server
- Traefik ingress controller
- Local Path Provisioner

## Validation

```bash
sudo k3s kubectl get nodes
sudo k3s kubectl get pods -A

