# Kubernetes Management from ops01

## Objective

Configure the dedicated ops01 management VM to remotely administer
the K3s Kubernetes cluster.

## Implementation

- Installed kubectl v1.36.3 on ops01.
- Copied the K3s administrative kubeconfig from the control-plane node.
- Configured the kubeconfig to use the control-plane API endpoint.
- Secured the local kubeconfig with restricted filesystem permissions.
- Verified remote Kubernetes API access from ops01.

## Validation

The following commands were successfully executed from ops01:

```bash
kubectl cluster-info
kubectl get nodes -o wide

All three Kubernetes nodes reported Ready:

k8s-control01
k8s-worker01
k8s-worker02

Architecture:

ops01 acts as the Kubernetes management workstation.

kubectl communicates with the Kubernetes API running on the
control-plane node, which manages the worker nodes and workloads.

Security:

The kubeconfig contains administrative Kubernetes credentials and is
not stored in this GitHub repository.
