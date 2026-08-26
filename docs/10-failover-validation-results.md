# Multi-Site Failover Validation Results

## Test Objective

Validate end-to-end application resilience following the complete loss of the DC-A Kubernetes environment.

The test was designed to validate:

- User traffic recovery
- Karmada cluster failure detection
- ClusterTaintPolicy behaviour
- NoExecute-based workload eviction
- Cross-cluster replica redistribution
- Kubernetes workload recovery
- Application availability through a stable frontend
- Controlled failback after site recovery

## Baseline State

Before triggering the failure, both Karmada member clusters were healthy.

```text
DC-A = Ready=True
DC-B = Ready=True
```

The NVR workload had a global desired state of two replicas.

Karmada placement was:

```text
DC-A = 1 replica
DC-B = 1 replica
```

HAProxy traffic state was:

```text
DC-A = Active
DC-B = Backup
```

The application was available through the single HAProxy frontend address:

```text
http://192.168.1.83:8082
```

## Baseline Validation Commands

Karmada member-cluster health was confirmed using:

```bash
km get clusters
```

The NVR Pod in DC-A was confirmed using:

```bash
kda get pods -n demo -l app=tvms-nvr-ui -o wide
```

The NVR Pod in DC-B was confirmed using:

```bash
kdb get pods -n demo -l app=tvms-nvr-ui -o wide
```

Karmada's placement decision was confirmed using:

```bash
km get resourcebinding tvms-nvr-ui-deployment \
  -n demo \
  -o jsonpath='{range .spec.clusters[*]}{.name}{" = "}{.replicas}{" replicas\n"}{end}'
```

The initial result was:

```text
dc-a = 1 replicas
dc-b = 1 replicas
```

## Failure Test

The complete DC-A Kubernetes environment was made unavailable.

This included:

- DC-A control-plane node
- DC-A worker01
- DC-A worker02

This simulated the loss of the entire Kubernetes site rather than an individual Pod or worker failure.

## Traffic Recovery

HAProxy continuously health-checks the Kubernetes NodePort endpoint in each site.

Following the DC-A outage, HAProxy marked the DC-A backend unavailable.

The traffic path changed from:

```text
User
 ↓
HAProxy
 ↓
DC-A
```

to:

```text
User
 ↓
HAProxy
 ↓
DC-B
```

The user continued to access the NVR application through the same HAProxy frontend address.

This demonstrated that the user-facing endpoint remained stable while the underlying site delivering the application changed.

## Karmada Failure Detection

Karmada independently monitored the health of the two member clusters.

Following loss of DC-A, Karmada detected that the cluster was no longer reporting:

```text
Ready=True
```

The configured `ClusterTaintPolicy` then applied:

```text
tvms.karmada.io/cluster-unavailable
effect: NoExecute
```

The taint marked DC-A as unsuitable for the affected workload.

## Workload Placement Recovery

Karmada recalculated the workload placement.

The original placement:

```text
DC-A = 1 replica
DC-B = 1 replica
```

changed to:

```text
DC-B = 2 replicas
```

DC-A was removed from the active workload placement.

The global desired application state remained two replicas.

## Kubernetes Recovery in DC-B

Once Karmada assigned both replicas to DC-B, the local Kubernetes cluster handled the additional workload.

The DC-B Deployment increased to two replicas.

The Kubernetes scheduler selected an eligible worker node for the additional Pod.

The worker's kubelet and container runtime then started the new application container.

The final DC-B workload state showed two healthy Pods:

```text
READY   STATUS
1/1     Running
1/1     Running
```

## Live Monitoring

Four live terminal views were used during the failover.

### Cluster Health

```text
Monitored:
Karmada member-cluster Ready state
```

This showed DC-A transitioning away from `Ready=True`.

### DC-A Taint

```text
Monitored:
DC-A Cluster object taints
```

This showed the `NoExecute` failure taint being applied.

### ResourceBinding

```text
Monitored:
Karmada workload placement
```

This showed the scheduling decision changing from:

```text
DC-A = 1
DC-B = 1
```

to:

```text
DC-B = 2
```

### DC-B Workload

```text
Monitored:
Deployment replica count and NVR Pods
```

This showed DC-B increasing from one application replica to two.

## Recovery Sequence

The observed sequence was:

```text
DC-A failure
        ↓
HAProxy detects failed backend
        ↓
User traffic moves to DC-B
        ↓
Karmada detects DC-A unhealthy
        ↓
ClusterTaintPolicy applies NoExecute
        ↓
Karmada recalculates placement
        ↓
DC-B assigned both replicas
        ↓
Kubernetes creates additional Pod
        ↓
Two healthy NVR replicas run in DC-B
```

Traffic recovery occurred before workload capacity had fully converged.

This demonstrated that traffic recovery and workload recovery are separate but complementary mechanisms.

## DC-A Restoration

The DC-A Kubernetes nodes were subsequently powered back on.

Karmada detected that the site had recovered:

```text
DC-A = Ready=True
DC-B = Ready=True
```

The failure `NoExecute` taint was removed automatically.

However, the workload remained:

```text
DC-B = 2 replicas
```

This confirmed that site recovery does not automatically trigger workload failback.

## Controlled Rebalancing

A Karmada `WorkloadRebalancer` was used to trigger a fresh scheduling decision.

The existing `PropagationPolicy` was re-evaluated against the current cluster health.

Because both DC-A and DC-B were healthy and the policy used equal weighted Divided scheduling, the workload returned to:

```text
DC-A = 1 replica
DC-B = 1 replica
```

## Final Validation

The full test sequence was:

```text
HEALTHY STATE

DC-A = 1
DC-B = 1

        ↓

DC-A FAILURE

        ↓

TRAFFIC FAILOVER

HAProxy
DC-A → DC-B

        ↓

WORKLOAD FAILOVER

Karmada
1+1 → 0+2

        ↓

DC-A RECOVERY

DC-A = Ready=True

        ↓

CONTROLLED REBALANCE

WorkloadRebalancer

        ↓

NORMAL STATE RESTORED

DC-A = 1
DC-B = 1
```

## What the Test Proved

### HAProxy

Maintained the user traffic path by directing traffic to the surviving Kubernetes site.

### Karmada

Detected the failed member cluster and recalculated the multi-cluster workload placement.

### Kubernetes

Scheduled and started the additional application capacity inside the surviving cluster.

### WorkloadRebalancer

Allowed the preferred active-active placement to be restored in a controlled manner after DC-A recovery.

## Architecture Principle

```text
HAProxy
chooses the traffic path

Karmada
chooses the cluster

Kubernetes
chooses the node
```

## Conclusion

The lab successfully demonstrated multi-site application resilience across independent Kubernetes clusters.

The desired application state remained constant throughout the failure event.

What changed was the location used to deliver that state.

The test also demonstrated that automatic failover and controlled failback can be treated as separate operational processes.
