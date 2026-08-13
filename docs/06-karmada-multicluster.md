# Karmada Multi-Cluster Orchestration

## Overview

This stage of the lab introduces Karmada as the multi-cluster orchestration layer.

Two independent Kubernetes clusters represent separate data centres:

- DC-A
- DC-B

Both clusters remain independent Kubernetes environments and are also connected to Azure Arc for hybrid management.

A separate Karmada management cluster coordinates workload placement across the two Kubernetes clusters.

## Architecture

```text
                          Karmada
                     Multi-Cluster Control
                            |
                  +---------+---------+
                  |                   |
                  v                   v
                DC-A                DC-B
             K3s Cluster         K3s Cluster
                  |                   |
             Worker Nodes        Worker Nodes
                  |                   |
             TVMS Console        TVMS Console

## Karmada Components
A dedicated VM named karmada-mgmt01 hosts the Karmada control plane.

The Karmada API is managed separately from the two member Kubernetes clusters.

Both clusters were registered with Karmada using Push mode.

CMD : 'km get clusters'

OUTPUT:

NAME   VERSION          MODE   READY
dc-a   v1.36.3+k3s1    Push   True
dc-b   v1.36.3+k3s1    Push   True

In Push mode, the Karmada control plane communicates directly with the Kubernetes API servers of the member clusters.

## Cluster Registration
DC-A was registered using its existing kubeconfig and context:

karmadactl join dc-a \
  --kubeconfig "$HOME/.kube/karmada.config" \
  --cluster-kubeconfig "$HOME/.kube/config" \
  --cluster-context dc-a-direct

DC-B was registered using:

karmadactl join dc-b \
  --kubeconfig "$HOME/.kube/karmada.config" \
  --cluster-kubeconfig "$HOME/.kube/dc-b.config" \
  --cluster-context dc-b-direct

## Application Demonstration
A management console workload was submitted to the Karmada API.

The workload consists of:
Kubernetes Namespace
Deployment
NodePort Service
ClusterPropagationPolicy
PropagationPolicy

The application workload is propagated to both DC-A and DC-B.
'km apply -f karmada/tvms-console.yaml'

## Propagation Policy
The PropagationPolicy selects both member clusters:
dc-a
dc-b

Replica scheduling is configured as:
'replicaSchedulingType: Duplicated'

This means each selected member cluster receives the full requested replica count.
For example:
Deployment replicas: 1

DC-A -> 1 replica
DC-B -> 1 replica

This represents the active-active application layer of the lab.

## Resource Bindings
Karmada creates ResourceBinding objects after matching the Kubernetes resources with the PropagationPolicy.
These can be viewed using:
'km get resourcebindings -n demo'

Example:
NAME                       SCHEDULED   FULLYAPPLIED
tvms-console-deployment    True        True
tvms-console-service       True        True

The ResourceBinding records Karmada's multi-cluster scheduling decision.

## The simplified workflow is:
Application YAML
      |
      v
Karmada API
      |
      v
PropagationPolicy
      |
      v
Karmada Scheduler
      |
      v
ResourceBinding
      |
      v
Work Resources
     / \
    /   \
 DC-A   DC-B

## Karmada vs Kubernetes Scheduling
Karmada and Kubernetes operate at different levels.
Karmada
   |
   -> Chooses the Kubernetes cluster

Kubernetes Scheduler
   |
   -> Chooses the node inside that cluster
