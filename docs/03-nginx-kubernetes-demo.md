# NGINX Kubernetes Deployment
## Objective

Deploy and test a containerised NGINX application on the K3s cluster
from the ops01 management workstation.

## Implementation

A declarative Kubernetes manifest was created containing:

- Namespace
- Deployment
- Node selector
- Service

The Deployment maintains four NGINX Pod replicas.

Application Pods are restricted to Kubernetes worker nodes using
node labels and a node selector.

The application is exposed using a NodePort Service.

## Kubernetes Objects

Deployment hierarchy:

Deployment
→ ReplicaSet
→ Pods
→ NGINX containers

## Validation

The environment was validated using:

```bash
kubectl get nodes
kubectl get deployments -n demo
kubectl get pods -n demo -o wide
kubectl get services -n demo

## Scaling Test

The Deployment was manually scaled from four to six replicas.

The declarative YAML was then reapplied to restore the defined
four-replica desired state.

## Self-Healing Test

A running NGINX Pod was manually deleted.

The Deployment controller detected that the actual replica count had
fallen below the desired state and automatically created a replacement
Pod.

## Result

The test demonstrated:

Kubernetes scheduling
Worker-node workload placement
Deployments
ReplicaSets
Pods
Services
Horizontal scaling
Declarative configuration
Desired-state reconciliation
Self-healing
