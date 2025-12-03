# Case Study: Performance Debugging & Optimization

## Overview

**Role:** DevOps/SRE Engineer
**Impact:** Resolved critical production issues affecting latency, reliability, and user experience

This document covers three significant performance issues I diagnosed and resolved:
1. SNAT Port Exhaustion
2. Database Connection Pool Starvation
3. Lambda Cold Start Latency

---

## Issue 1: SNAT Port Exhaustion on EKS

### Symptoms
- Intermittent connection timeouts to external APIs
- Errors spiking during peak traffic (10am-2pm)
- `connection timed out` errors in application logs
- Some pods affected while others worked fine

### Architecture Context

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    EKS Cluster Network Architecture                          │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Private Subnets                               │   │
│  │                                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │   │
│  │  │  Pod A   │  │  Pod B   │  │  Pod C   │  │  Pod D   │            │   │
│  │  │ 10.0.1.5 │  │ 10.0.1.6 │  │ 10.0.2.7 │  │ 10.0.2.8 │            │   │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘            │   │
│  │       │             │             │             │                   │   │
│  │       └─────────────┴─────────────┴─────────────┘                   │   │
│  │                           │                                         │   │
│  │                           ▼                                         │   │
│  │              ┌────────────────────────┐                             │   │
│  │              │      NAT Gateway       │                             │   │
│  │              │    (Single AZ)         │ ◀── BOTTLENECK!             │   │
│  │              │                        │                             │   │
│  │              │  Available ports:      │                             │   │
│  │              │  55,000 per IP         │                             │   │
│  │              │  (minus reserved)      │                             │   │
│  │              └───────────┬────────────┘                             │   │
│  └──────────────────────────┼──────────────────────────────────────────┘   │
│                             │                                              │
│                             ▼                                              │
│                    ┌────────────────┐                                      │
│                    │  External API  │                                      │
│                    │   (Stripe,     │                                      │
│                    │   Twilio, etc) │                                      │
│                    └────────────────┘                                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Root Cause Analysis

```
Problem: Single NAT Gateway with limited SNAT ports

SNAT Port Allocation:
┌─────────────────────────────────────────────────────────────┐
│  Each connection to external IP:PORT needs unique source   │
│  port from NAT Gateway                                      │
│                                                             │
│  NAT GW IP: 52.1.2.3                                       │
│  Available ports: ~55,000                                   │
│                                                             │
│  Connection 1: 52.1.2.3:32001 → api.stripe.com:443        │
│  Connection 2: 52.1.2.3:32002 → api.stripe.com:443        │
│  Connection 3: 52.1.2.3:32003 → api.stripe.com:443        │
│  ...                                                        │
│  Connection 55000: 52.1.2.3:65535 → PORT EXHAUSTION!       │
└─────────────────────────────────────────────────────────────┘

With 200 pods making 300 connections each = 60,000 ports needed!
```

### Investigation Process

```bash
# 1. Checked CloudWatch NAT Gateway metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/NATGateway \
  --metric-name ErrorPortAllocation \
  --dimensions Name=NatGatewayId,Value=nat-xxxxx

# 2. Found ErrorPortAllocation spikes correlating with timeouts

# 3. Calculated connection requirements
# Pods: 200, Avg connections per pod: 300
# Total: 60,000 > 55,000 available ports

# 4. Identified long-lived connections holding ports
kubectl exec -it pod-name -- ss -tn | grep ESTABLISHED | wc -l
```

### Solution

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Solution: Multi-NAT Architecture                      │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        Private Subnets                               │   │
│  │                                                                      │   │
│  │  AZ-A                    AZ-B                    AZ-C               │   │
│  │  ┌──────────┐           ┌──────────┐           ┌──────────┐        │   │
│  │  │  Pods    │           │  Pods    │           │  Pods    │        │   │
│  │  └────┬─────┘           └────┬─────┘           └────┬─────┘        │   │
│  │       │                      │                      │               │   │
│  │       ▼                      ▼                      ▼               │   │
│  │  ┌──────────┐           ┌──────────┐           ┌──────────┐        │   │
│  │  │ NAT GW 1 │           │ NAT GW 2 │           │ NAT GW 3 │        │   │
│  │  │ 55K ports│           │ 55K ports│           │ 55K ports│        │   │
│  │  └──────────┘           └──────────┘           └──────────┘        │   │
│  │                                                                      │   │
│  │  Total available: 165,000 ports (3x improvement)                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Additional optimizations:**
- Enabled connection reuse in HTTP clients
- Reduced idle connection timeout
- Implemented connection pooling for external APIs

### Result
- **Before:** 500+ timeout errors/day during peak
- **After:** Zero SNAT-related errors
- **Cost:** +$90/month for additional NAT Gateways (justified by reliability)

---

## Issue 2: Database Connection Pool Starvation

### Symptoms
- Periodic `connection timeout` errors to PostgreSQL
- Application latency spikes every 30-60 seconds
- Database CPU normal, but connection count at max
- Errors: `too many connections for role "app"`

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Connection Pool Problem                                   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Kubernetes Pods                                  │   │
│  │                                                                      │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐            │   │
│  │  │ Pod 1  │ │ Pod 2  │ │ Pod 3  │ │ Pod 4  │ │ Pod 5  │  (×20)     │   │
│  │  │Pool:20 │ │Pool:20 │ │Pool:20 │ │Pool:20 │ │Pool:20 │            │   │
│  │  └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘            │   │
│  │      │          │          │          │          │                  │   │
│  │      └──────────┴──────────┼──────────┴──────────┘                  │   │
│  │                            │                                        │   │
│  │                            ▼                                        │   │
│  │               Total connections requested: 400                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                               │                                            │
│                               ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    RDS PostgreSQL                                    │   │
│  │                                                                      │   │
│  │              max_connections = 200  ◀── LIMIT!                      │   │
│  │                                                                      │   │
│  │              20 pods × 20 pool size = 400 connections               │   │
│  │              But only 200 available!                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Investigation

```bash
# 1. Check current connections
psql -c "SELECT count(*) FROM pg_stat_activity WHERE state = 'active';"

# 2. Check connection states
psql -c "SELECT state, count(*) FROM pg_stat_activity GROUP BY state;"
# Found: 180 idle, 15 active, 5 idle in transaction

# 3. Check application pool config
# Found: pool_size=20, max_overflow=10, pool_timeout=30

# 4. Calculate total possible connections
# 20 pods × (20 + 10 overflow) = 600 possible connections!
```

### Solution: PgBouncer Connection Pooler

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Solution: PgBouncer Proxy                                 │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Kubernetes Pods                                  │   │
│  │                                                                      │   │
│  │  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐            │   │
│  │  │ Pod 1  │ │ Pod 2  │ │ Pod 3  │ │ Pod 4  │ │ Pod 5  │  (×20)     │   │
│  │  │Pool:10 │ │Pool:10 │ │Pool:10 │ │Pool:10 │ │Pool:10 │            │   │
│  │  └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘ └───┬────┘            │   │
│  │      │          │          │          │          │                  │   │
│  │      └──────────┴──────────┼──────────┴──────────┘                  │   │
│  │                            │                                        │   │
│  │                            ▼                                        │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │                    PgBouncer                                 │   │   │
│  │  │                                                              │   │   │
│  │  │   Mode: transaction pooling                                  │   │   │
│  │  │   max_client_conn = 1000 (can handle all pods)              │   │   │
│  │  │   default_pool_size = 50 (actual DB connections)            │   │   │
│  │  │                                                              │   │   │
│  │  │   Multiplexes 200 client connections → 50 DB connections    │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                               │                                            │
│                               ▼                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    RDS PostgreSQL                                    │   │
│  │                                                                      │   │
│  │              Now only 50 actual connections!                        │   │
│  │              Headroom for scaling: 200 - 50 = 150 available         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Result
- **Before:** 50+ connection errors/hour during deployments
- **After:** Zero connection errors
- **Bonus:** Can now scale to 100+ pods without DB changes

---

## Issue 3: Lambda Cold Start Latency

### Symptoms
- First request after idle period: 3-5 second latency
- Subsequent requests: 50-100ms
- User complaints about "slow loading" in morning
- CloudWatch showing high initialization duration

### Cold Start Analysis

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Lambda Cold Start Timeline                                │
│                                                                             │
│  Cold Start (first invocation):                                            │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  │◀─────── Init (2-4s) ────────▶│◀── Handler (50ms) ──▶│           │    │
│  │  │                               │                      │           │    │
│  │  │  Download    Start    Init   │      Business       │  Total:   │    │
│  │  │   Code     Runtime   Code    │       Logic         │  ~3-4s    │    │
│  │  │  (500ms)  (1000ms) (1500ms)  │                      │           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  Warm Start (subsequent invocations):                                      │
│  ┌────────────────────────────────────────────────────────────────────┐    │
│  │  │◀── Handler (50ms) ──▶│                                          │    │
│  │  │                      │                                          │    │
│  │  │    Business Logic    │  Total: ~50ms                           │    │
│  └────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Investigation

```bash
# 1. Analyzed CloudWatch Logs Insights
fields @timestamp, @duration, @billedDuration, @initDuration
| filter @type = "REPORT"
| stats avg(@initDuration) as avgInit,
        pct(@initDuration, 99) as p99Init,
        count(*) as invocations
| sort avgInit desc

# Found: avgInit = 2,800ms, p99Init = 4,200ms

# 2. Identified heavy initialization
# - Large dependency bundle (150MB)
# - Database connection on init
# - AWS SDK client initialization
```

### Solution: Multi-Pronged Optimization

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Cold Start Optimizations                                  │
│                                                                             │
│  1. Provisioned Concurrency                                                │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐       │   │
│  │  │ Warm    │ │ Warm    │ │ Warm    │ │ Warm    │ │ Warm    │       │   │
│  │  │Instance │ │Instance │ │Instance │ │Instance │ │Instance │       │   │
│  │  │  (PC)   │ │  (PC)   │ │  (PC)   │ │  (PC)   │ │  (PC)   │       │   │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘       │   │
│  │                                                                      │   │
│  │  Provisioned Concurrency = 5 (always warm, no cold starts)         │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  2. Code Optimization                                                      │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │  Before:                         After:                             │   │
│  │  ┌──────────────────────┐       ┌──────────────────────┐           │   │
│  │  │ import entire_aws_sdk│       │ import { S3 } from   │           │   │
│  │  │ import all_utilities │  ──▶  │   '@aws-sdk/client-s3'│          │   │
│  │  │ Bundle: 150MB        │       │ Bundle: 15MB         │           │   │
│  │  └──────────────────────┘       └──────────────────────┘           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  3. Connection Reuse                                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │  // Initialize outside handler (reused across invocations)          │   │
│  │  const dbPool = initializePool();  // Only runs on cold start       │   │
│  │                                                                      │   │
│  │  export const handler = async (event) => {                          │   │
│  │    const client = await dbPool.connect();  // Reuses warm conn      │   │
│  │    // ... business logic                                            │   │
│  │  };                                                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Result

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Cold start duration | 3,500ms | 800ms | 77% reduction |
| P99 latency | 4,200ms | 200ms | 95% reduction |
| Bundle size | 150MB | 15MB | 90% reduction |
| User complaints | 10/week | 0/week | 100% elimination |

---

## Key Takeaways

1. **Metrics are essential** - All three issues were identified through proper observability
2. **Understand the system** - Each problem required deep knowledge of underlying architecture
3. **Root cause, not symptoms** - Quick fixes often mask deeper issues
4. **Cost-benefit analysis** - Sometimes the fix costs money (NAT GWs, Provisioned Concurrency) but saves more in reliability

## Technologies & Tools Used

`CloudWatch` `CloudWatch Logs Insights` `Prometheus` `Grafana` `tcpdump` `pg_stat_activity` `AWS X-Ray` `Lambda Power Tuning`
