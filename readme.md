<div align="center">

# Distributed Cron Scheduler in Swift (Vapor)

**Leader election · Failover · Cron jobs · PostgreSQL · Docker**

[![Swift](https://img.shields.io/badge/Swift-5.9-red?style=flat-square&logo=swift)](https://swift.org)
[![Vapor](https://img.shields.io/badge/Vapor-4-blue?style=flat-square)](https://vapor.codes)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

</div>

## Overview

A fault‑tolerant distributed cron scheduler. Multiple nodes compete for leadership using a PostgreSQL advisory lock. Only the leader executes jobs. If it fails, a new leader takes over within seconds.

## Features

- **Leader election** via database lock with TTL.
- **Cron parser** (supports `*`, `*/5`, `1-10`, `1,2,3`).
- **Retries** with exponential backoff.
- **Persistent jobs** (PostgreSQL + Fluent).
- **REST API** to manage jobs and see run history.
- **Docker Compose** to run a 2‑node cluster.

## Quick Start

```bash
git clone ...
cd distributed-cron-scheduler
docker-compose up --build
Then open http://localhost:8081 (node1) or 8082 (node2).

API Examples
bash
# Create a job (every minute, echo hello)
curl -X POST http://localhost:8081/jobs \
  -H "Content-Type: application/json" \
  -d '{"cron":"* * * * *","command":"echo hello","retries":2}'

# List jobs
curl http://localhost:8081/jobs

# Get job runs
curl http://localhost:8081/jobs/<job-id>/runs

# Delete job
curl -X DELETE http://localhost:8081/jobs/<job-id>
Architecture
LeaderElector (actor) – renews lock every 5s.

CronScheduler – runs every minute, checks if leader, then scans jobs.

JobExecutor – runs command, records result.

PostgreSQL – stores jobs, runs, and leadership lock.
License
MIT

</div> ```