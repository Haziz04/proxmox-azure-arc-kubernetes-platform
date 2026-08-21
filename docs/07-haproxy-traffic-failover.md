# HAProxy Traffic Failover

## Objective

Provide a single stable application entry point across the two independent
Kubernetes sites.

HAProxy is used as the lab traffic-management layer.

Normal traffic state:

- DC-A = active
- DC-B = healthy backup
- Application frontend = `192.168.1.83:8082`
- Kubernetes NVR NodePort = `30082`

## Traffic Flow

User
  |
  v
HAProxy :8082
  |
  +--> DC-A :30082 (Active)
  |
  +--> DC-B :30082 (Backup)

The NodePort forwards traffic into the Kubernetes Service, which selects
a healthy NVR application Pod.

## HAProxy Configuration

```text
frontend nvr_frontend
    bind *:8082
    mode http
    default_backend nvr_sites

backend nvr_sites
    mode http
    option httpchk GET /
    server dc-a-nvr 192.168.1.67:30082 check fall 2 rise 2
    server dc-b-nvr 192.168.1.200:30082 check backup fall 2 rise 2

## HAProxy Statistics
The HAProxy statistics interface is exposed on:
http://192.168.1.83:8404/stats

This provides visibility of:
 backend health
 active / backup state
 traffic counters
 failover behaviour
 
## Responsibility Separation
HAProxy maintains the user traffic path.
Karmada independently maintains workload placement and application capacity.
During a DC-A failure:
HAProxy detects DC-A is unavailable.
Traffic moves to DC-B.
Karmada subsequently recalculates workload placement.
DC-B absorbs the missing application capacity.
