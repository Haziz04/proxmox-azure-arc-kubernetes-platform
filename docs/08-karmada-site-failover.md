# Karmada Site Failover

## Objective

Validate automatic workload recovery following the complete loss of one Kubernetes site.

The lab uses two independent Kubernetes clusters:

- DC-A
- DC-B

Karmada manages workload placement across both clusters.

The NVR workload has a global desired state of two replicas.

## Normal Operating State

Under normal conditions, the workload is distributed evenly:

```text
DC-A = 1 replica
DC-B = 1 replica
```

This provides an active-active workload model across the two Kubernetes sites.

## Failover Configuration

Karmada cluster failover support was explicitly enabled together with NoExecute-based eviction.

The following capabilities were enabled:

- Karmada Failover feature
- NoExecute taint eviction
- NoExecute ClusterTaintPolicy support
- Graceful purge behaviour

## ClusterTaintPolicy

A `ClusterTaintPolicy` monitors the health condition of both member clusters.

If a cluster stops reporting:

```text
Ready=True
```

the policy applies the following taint:

```text
tvms.karmada.io/cluster-unavailable
effect: NoExecute
```

This marks the failed cluster as unsuitable for the affected workload.

When the cluster becomes healthy again and returns to `Ready=True`, the failure taint is removed.

## Failover Sequence

During the DC-A failure test:

```text
DC-A becomes unavailable
        ↓
Karmada detects DC-A is no longer Ready
        ↓
ClusterTaintPolicy applies NoExecute
        ↓
DC-A becomes unsuitable for the workload
        ↓
Karmada recalculates placement
        ↓
DC-B absorbs the missing replica
```

The placement changes from:

```text
DC-A = 1 replica
DC-B = 1 replica
```

to:

```text
DC-A = 0 replicas
DC-B = 2 replicas
```

The desired application state remains two replicas.

Only the location of those replicas changes.

## Traffic and Workload Recovery

Traffic recovery and workload recovery are handled independently.

### HAProxy

HAProxy maintains the user traffic path.

Under normal conditions:

```text
DC-A = Active
DC-B = Backup
```

If DC-A becomes unavailable, HAProxy health checks mark the DC-A backend down and redirect traffic to DC-B.

### Karmada

Karmada maintains the desired workload placement and capacity across the Kubernetes estate.

Following loss of DC-A, Karmada recalculates the workload placement so that DC-B carries both required replicas.

### Kubernetes

Once Karmada assigns the additional replica to DC-B, the Kubernetes control plane inside DC-B handles the local scheduling.

The Kubernetes scheduler selects an eligible worker node, and kubelet together with containerd starts the additional Pod.

## Responsibility Separation

```text
HAProxy
= chooses the traffic path

Karmada
= chooses the Kubernetes cluster

Kubernetes
= chooses the worker node
```

This separation allows the user traffic path to recover before workload capacity has fully converged.

## Key Principle

The desired application state does not change during failover.

Only the location used to deliver that desired state changes.
