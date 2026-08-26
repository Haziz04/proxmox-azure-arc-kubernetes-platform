# Karmada Failback and Workload Rebalancing

## Objective

Document the behaviour observed when a failed Kubernetes member cluster is restored and explain how normal workload distribution is re-established.

## State After Failover

Following the loss of DC-A, Karmada moved the full NVR workload capacity to DC-B.

The resulting placement was:

```text
DC-A = 0 replicas
DC-B = 2 replicas
```

DC-B continued to provide the required two-replica application state.

## DC-A Recovery

The DC-A Kubernetes control-plane and worker nodes were powered back on.

Once the cluster recovered, Karmada reported:

```text
DC-A = Ready=True
DC-B = Ready=True
```

The `ClusterTaintPolicy` then removed the failure `NoExecute` taint from DC-A.

DC-A was therefore healthy and eligible for scheduling again.

## Existing Placement Remains Stable

Although DC-A had recovered, the existing workload placement remained:

```text
DC-B = 2 replicas
```

Karmada did not immediately move one replica back to DC-A simply because the cluster had returned to a healthy state.

This separates automatic failover from controlled failback.

## WorkloadRebalancer

Karmada provides a `WorkloadRebalancer` API object for explicitly triggering a fresh scheduling decision.

The following object was used:

```yaml
apiVersion: apps.karmada.io/v1alpha1
kind: WorkloadRebalancer

metadata:
  name: tvms-nvr-ui-rebalance

spec:
  ttlSecondsAfterFinished: 300

  workloads:
    - apiVersion: apps/v1
      kind: Deployment
      name: tvms-nvr-ui
      namespace: demo
```

## What the WorkloadRebalancer Does

The `WorkloadRebalancer` does not define the workload placement rules itself.

Those rules remain in the existing `PropagationPolicy`.

Instead, the object tells Karmada to:

```text
Re-evaluate the selected workload
        ↓
Read the existing PropagationPolicy
        ↓
Check the currently healthy clusters
        ↓
Run a fresh scheduling decision
        ↓
Update the ResourceBinding
```

The existing `PropagationPolicy` defines:

```text
Target clusters:
DC-A
DC-B

Scheduling:
Divided

Weight:
DC-A = 1
DC-B = 1
```

Because both clusters are healthy again, the fresh scheduling decision returns the workload to:

```text
DC-A = 1 replica
DC-B = 1 replica
```

## ResourceBinding

The `ResourceBinding` records Karmada's current placement decision.

Before rebalancing:

```text
DC-B = 2 replicas
```

After the WorkloadRebalancer triggers a fresh scheduling decision:

```text
DC-A = 1 replica
DC-B = 1 replica
```

The `ResourceBinding` is maintained by Karmada rather than being manually created as part of normal workload deployment.

## WorkloadRebalancer Lifecycle

The YAML file remains stored locally and can also remain version-controlled in GitHub.

The Kubernetes-style `WorkloadRebalancer` object created inside the Karmada API is temporary.

The following setting:

```yaml
ttlSecondsAfterFinished: 300
```

allows the completed WorkloadRebalancer object to be cleaned up after 300 seconds.

The source YAML file itself is not deleted.

## Controlled Failback Model

The operational model is:

```text
NORMAL STATE
DC-A = 1
DC-B = 1

        ↓

FAILURE
DC-A becomes unhealthy

        ↓

AUTOMATIC FAILOVER
NoExecute applied
DC-B = 2

        ↓

RECOVERY
DC-A returns Ready
Failure taint removed

        ↓

PLACEMENT REMAINS STABLE
DC-B = 2

        ↓

CONTROLLED FAILBACK
Validate DC-A
Trigger WorkloadRebalancer

        ↓

NORMAL STATE RESTORED
DC-A = 1
DC-B = 1
```

## Production Consideration

In production, a recovered site would normally be validated before workloads are moved back.

Checks could include:

- Kubernetes node health
- Network connectivity
- Storage availability
- Application dependencies
- Monitoring status
- Infrastructure alarms
- Service health

Once the recovered site is confirmed stable, an operational runbook or automation workflow could create a new `WorkloadRebalancer` object.

This avoids immediately moving workloads back to a site that has only just recovered.

## Key Principle

Automatic failover protects service availability.

Controlled rebalancing restores the preferred operating model once the recovered site has been validated.
