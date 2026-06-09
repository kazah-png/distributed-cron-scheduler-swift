<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:0d1117,50:1c0a00,100:2e1600&height=130&section=header&text=distributed-cron-scheduler&fontSize=34&fontColor=e6edf3&animation=fadeIn&fontAlignY=55" />
</div>

<div align="center">

[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![Vapor](https://img.shields.io/badge/Vapor-4-0099CC?style=flat)](https://vapor.codes)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Fluent%20ORM-4169E1?style=flat&logo=postgresql&logoColor=white)]()
[![License](https://img.shields.io/badge/License-MIT-3fb950?style=flat)](LICENSE)
[![Docker](https://img.shields.io/badge/Docker-2--node%20cluster-2496ED?style=flat&logo=docker&logoColor=white)]()

**Fault-tolerant distributed cron job scheduler in Swift / Vapor.**  
Leader election via PostgreSQL advisory lock · Automatic failover · Exponential backoff retries · REST API

</div>

---

## Overview

Multiple scheduler nodes compete for leadership using a **PostgreSQL advisory lock with TTL**. Only the elected leader executes jobs; all other nodes stay idle in standby. If the leader crashes or stops renewing the lock, a standby node acquires it within seconds and takes over — no manual intervention, no split-brain.

Jobs are stored persistently in PostgreSQL via Fluent ORM. The full run history is retained and queryable through the REST API.

---

## Architecture

```
┌───────────────────────┐    ┌───────────────────────┐
│       Node 1          │    │       Node 2          │
│  LeaderElector        │    │  LeaderElector        │
│  (renews lock / 5s)   │    │  (polls lock / 5s)    │
│                       │    │                       │
│  CronScheduler ──────►│    │  CronScheduler        │
│  (runs jobs if leader)│    │  (idle — not leader)  │
│                       │    │                       │
│  JobExecutor          │    │  JobExecutor          │
│  REST API :8081       │    │  REST API :8082       │
└───────────┬───────────┘    └───────────┬───────────┘
            │                            │
            └────────────┬───────────────┘
                         │
                  ┌──────▼──────┐
                  │  PostgreSQL  │
                  │  jobs        │
                  │  job_runs    │
                  │  leader_lock │
                  └─────────────┘
```

**Leader election flow:**
1. Each node attempts `pg_try_advisory_lock(key)` on startup and every 5 seconds.
2. The node that holds the lock is the leader; it renews by refreshing a `last_heartbeat` timestamp.
3. If `last_heartbeat` is older than the TTL (15s), any standby node may attempt to acquire the lock.
4. The `CronScheduler` checks leadership before each tick — no job runs on a non-leader node.

---

## Features

| Feature | Details |
|---|---|
| **Leader election** | PostgreSQL advisory lock with TTL; no external coordination service needed |
| **Cron parser** | Supports `*`, `*/n`, `a-b` ranges, `a,b,c` lists — standard 5-field cron syntax |
| **Retries** | Per-job retry count with exponential backoff (`base_delay * 2^attempt`) |
| **Persistent jobs** | PostgreSQL + Fluent ORM; jobs survive cluster restarts |
| **Run history** | Every execution recorded with start time, duration, exit status, and stdout/stderr |
| **REST API** | Full CRUD for jobs; run history per job |
| **Docker Compose** | 2-node cluster + PostgreSQL with a single command |

---

## Quick Start

```bash
git clone https://github.com/kazah-png/distributed-cron-scheduler-swift.git
cd distributed-cron-scheduler-swift
docker-compose up --build
```

Node 1 at `http://localhost:8081` · Node 2 at `http://localhost:8082`

---

## API

### Create a job

```bash
curl -X POST http://localhost:8081/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "cron":    "*/5 * * * *",
    "command": "echo hello",
    "retries": 2
  }'
```

```json
{"id": "550e8400-e29b-41d4-a716-446655440000", "cron": "*/5 * * * *", "command": "echo hello", "retries": 2}
```

### List all jobs

```bash
curl http://localhost:8081/jobs
```

### Get run history for a job

```bash
curl http://localhost:8081/jobs/<job-id>/runs
```

```json
[
  {
    "id":        "...",
    "startedAt": "2026-06-09T10:00:00Z",
    "duration":  12,
    "status":    "success",
    "output":    "hello"
  }
]
```

### Delete a job

```bash
curl -X DELETE http://localhost:8081/jobs/<job-id>
```

### Endpoints summary

| Endpoint | Method | Description |
|---|---|---|
| `/jobs` | GET | List all jobs |
| `/jobs` | POST | Create a job |
| `/jobs/:id` | DELETE | Delete a job |
| `/jobs/:id/runs` | GET | Run history for a job |
| `/leader` | GET | Which node currently holds the lock |

---

## Cron syntax

| Expression | Meaning |
|---|---|
| `* * * * *` | Every minute |
| `*/5 * * * *` | Every 5 minutes |
| `0 * * * *` | Every hour at :00 |
| `0 9 * * 1-5` | Weekdays at 09:00 |
| `30 6 1,15 * *` | 1st and 15th of each month at 06:30 |

Fields: `minute hour day-of-month month day-of-week`

---

## Failover test

With the cluster running, stop node 1:

```bash
docker-compose stop node1
```

Within 15 seconds (the lock TTL), node 2 acquires leadership and resumes executing jobs. Restart node 1 and it returns to standby — no duplicate executions.

---

## Limitations

- **Single PostgreSQL instance** — the database is the single point of failure. Add streaming replication for HA.
- **No quorum** — advisory lock is binary; a network partition between nodes and PostgreSQL can cause a temporary gap in scheduling.
- **Command execution** — jobs run as shell commands on the leader node. For distributed workloads, replace `JobExecutor` with an HTTP call to a worker pool.

---

<div align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&color=0:2e1600,50:1c0a00,100:0d1117&height=80&section=footer" />
</div>
