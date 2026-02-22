---
title: AAP Error Classification Taxonomy
category: references
sources:
  - title: "Red Hat AAP 2.6 Troubleshooting Guide"
    url: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs
    sections: "Job failure categories, error patterns"
    date_accessed: 2026-02-22
  - title: "Ansible Module Error Handling"
    url: https://docs.ansible.com/ansible/latest/reference_appendices/common_return_values.html
    sections: "Return values, failure modes"
    date_accessed: 2026-02-22
tags: [error-classification, troubleshooting, platform-vs-code, taxonomy]
applies_to: [aap2.4, aap2.5, aap2.6]
semantic_keywords:
  - error classification
  - platform error vs code error
  - root cause categorization
  - failure taxonomy
  - unreachable vs failed
  - ansible error types
  - troubleshooting decision tree
use_cases:
  - forensic_troubleshooting
  - error_classification
  - resolution_recommendation
related_docs:
  - aap/troubleshooting-jobs.md
  - aap/job-launching-best-practices.md
last_updated: 2026-02-22
---

# AAP Error Classification Taxonomy

## Overview

When an AAP job fails, the critical first step is classifying the root cause as either a **Platform Issue** (infrastructure/environment) or a **Code Issue** (playbook/automation logic). This classification determines the resolution path and the responsible team.

## When to Use This

- When performing forensic analysis on a failed job
- When determining whether the failure is a developer's or admin's responsibility
- When generating resolution recommendations
- When correlating job events with host system facts

## Primary Classification: Platform vs Code

### Platform Issues (Admin's Responsibility)

Issues stemming from the infrastructure, environment, or AAP configuration. The playbook logic is correct, but the environment prevents successful execution.

| Category | Examples | Resolution Owner |
|----------|---------|-----------------|
| **Network/Connectivity** | Host unreachable, SSH timeout, DNS failure | Network/Infrastructure team |
| **Authentication** | Wrong SSH key, expired token, sudo failure | AAP Admin / Security team |
| **Resource Exhaustion** | Disk full, OOM, CPU overload | Infrastructure/Platform team |
| **Platform Drift** | Wrong OS version, missing packages, SELinux mismatch | Platform/Compliance team |
| **AAP Configuration** | Wrong EE image, missing credentials, project sync failure | AAP Admin |
| **External Dependencies** | API unavailable, database down, DNS failure | Service owner |

### Code Issues (Developer's Responsibility)

Issues stemming from the playbook, role, or automation logic. The environment is healthy, but the automation code has bugs.

| Category | Examples | Resolution Owner |
|----------|---------|-----------------|
| **Module Errors** | Wrong module parameters, missing required args | Automation Developer |
| **Logic Errors** | Wrong conditionals, incorrect variable values | Automation Developer |
| **Template Errors** | Jinja2 syntax errors, undefined variables | Automation Developer |
| **Collection Issues** | Missing FQCN, wrong collection version | Automation Developer |
| **Idempotency Failures** | Task not idempotent, creates drift on re-run | Automation Developer |
| **Error Handling** | Missing rescue blocks, no rollback logic | Automation Developer |

### Mixed Issues (Requires Collaboration)

Some failures require both platform and code changes:

| Scenario | Platform Action | Code Action |
|----------|----------------|-------------|
| Service fails due to config syntax AND disk full | Free disk space | Fix config template |
| Package conflict due to third-party repo | Clean up repos | Pin package version in playbook |
| Timeout due to slow host AND no async usage | Scale host resources | Add async/poll to long tasks |

## Detailed Error Patterns

### Unreachable Errors (Always Platform)

```
Event: runner_on_unreachable

Patterns:
- "Failed to connect to the host via ssh"
  → SSH connectivity issue (firewall, key, DNS)

- "Connection timed out"
  → Network routing or host down

- "Name or service not known"
  → DNS resolution failure

- "Permission denied (publickey,gssapi-keyex,gssapi-with-mic)"
  → SSH key not authorized on target

- "Connection refused"
  → SSH daemon not running or wrong port

Classification: ALWAYS Platform Issue
Responsibility: Infrastructure / Network team
```

### Failed Errors (Requires Analysis)

```
Event: runner_on_failed

Must analyze error message to classify:

Platform Indicators:
- "No space left on device" → Disk full
- "Cannot allocate memory" → OOM
- "sudo: a password is required" → Credential config
- "Connection to database failed" → External dependency
- "Certificate verify failed" → TLS/Certificate issue
- "Permission denied" (file/directory) → File permissions
- "SELinux is preventing" → SELinux policy

Code Indicators:
- "The module <X> was not found" → Missing collection
- "Unsupported parameters" → Wrong module arguments
- "undefined variable" → Template/variable error
- "Syntax error" → YAML or Jinja2 syntax
- "changed_when" errors → Idempotency issue
- "AnsibleFilterError" → Jinja2 filter error
```

## Severity Scoring

### Error Severity Matrix

| Severity | Criteria | Response Time |
|----------|----------|---------------|
| **Critical** | Production job failed, all hosts affected | Immediate |
| **High** | Production job failed, subset of hosts | Within 1 hour |
| **Medium** | Non-production job failed, blocking deployment | Within 4 hours |
| **Low** | Non-production job failed, non-blocking | Within 24 hours |

### Severity Determination Logic

```
IF environment == production:
    IF all_hosts_failed:
        severity = CRITICAL
    ELIF >50% hosts failed:
        severity = HIGH
    ELSE:
        severity = MEDIUM
ELIF environment == staging:
    IF blocks_production_deployment:
        severity = MEDIUM
    ELSE:
        severity = LOW
ELSE:
    severity = LOW
```

## Error Resolution Priority

### Priority Matrix

| Error Type | Blocking? | Impact | Priority |
|-----------|-----------|--------|----------|
| Unreachable (all hosts) | Yes | Total failure | P0 - Fix immediately |
| Failed (privilege escalation) | Yes | Cannot execute | P0 - Fix credential |
| Failed (module not found) | Yes | Cannot execute | P1 - Fix EE/collection |
| Failed (service start) | Partial | Some hosts affected | P1 - Investigate per host |
| Failed (package conflict) | Partial | Some hosts affected | P2 - Resolve conflict |
| Failed (timeout) | Partial | Slow execution | P2 - Optimize or scale |
| Skipped (unexpected) | No | Logic issue | P3 - Review conditions |

## Correlation with Host Facts

### Fact-Based Root Cause Detection

After classifying the error type, correlate with host facts:

| Error | Host Fact to Check | Finding → Root Cause |
|-------|-------------------|---------------------|
| Service failed to start | `ansible_mounts[*].size_available` | <5% free → Disk full (Platform) |
| Package update failed | `ansible_distribution_major_version` | RHEL 7 with DNF task → Wrong package manager (Code) |
| Module not found | `ansible_python.version` | Python 2.7 → Needs Python 3 module (Platform/Code) |
| Permission denied | `ansible_selinux.status` | "enforcing" → SELinux blocking (Platform) |
| Timeout | `ansible_processor_vcpus` | 1 vCPU on heavy workload → Under-provisioned (Platform) |
| Service config error | `ansible_distribution_major_version` | RHEL 9 config path differs from RHEL 7 → Version-specific code needed (Code) |

### Host Health Assessment Template

```
Host Health Assessment: <hostname>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

OS: RHEL <version> (Supported: Yes/No)
Uptime: <days> days
Last Reboot: <date>

Resources:
  CPU: <count> vCPUs, Load: <load_avg>
  Memory: <total> MB total, <free> MB free (<percent>% used)
  Disk /:     <total> GB, <available> GB free (<percent>% used)
  Disk /var:  <total> GB, <available> GB free (<percent>% used)
  Disk /tmp:  <total> GB, <available> GB free (<percent>% used)

Platform:
  SELinux: <status> (Expected: enforcing)
  Python: <version> (Expected: 3.x for RHEL 8+)
  Package Manager: <dnf|yum>
  Subscription: <active|expired|unknown>

Findings:
  ✓ / ✗ OS version supported
  ✓ / ✗ Disk space adequate (>10% free on all mounts)
  ✓ / ✗ Memory adequate (>10% free)
  ✓ / ✗ SELinux in expected state
  ✓ / ✗ Python version compatible
  ✓ / ✗ Subscription active
```

## Resolution Templates

### Platform Issue Resolution

```
🔧 Root Cause: Platform Issue - <category>

Affected Host(s): <host_list>
Error: <error_message>

Diagnosis:
  <specific finding from host fact correlation>

Resolution:
  Per Red Hat AAP Troubleshooting Guide:
  1. <step 1>
  2. <step 2>
  3. <step 3>

  📖 Reference: <Red Hat doc URL>

After Fix:
  Re-run the job: Job Template "<name>" with same parameters
```

### Code Issue Resolution

```
🐛 Root Cause: Code Issue - <category>

Failing Task: <task_name>
Module: <module_name>
Error: <error_message>

Diagnosis:
  <specific code issue identified>

Resolution:
  1. <code change required>
  2. <testing recommendation>

  📖 Reference: <Ansible module docs URL>

After Fix:
  1. Commit code change to project repo
  2. Sync project in AAP
  3. Re-run the job
```

## Related Documentation

- [AAP Job Troubleshooting Guide](../aap/troubleshooting-jobs.md) - Detailed troubleshooting patterns
- [Job Launching Best Practices](../aap/job-launching-best-practices.md) - Prevent failures with governance

## Quick Reference

| Signal | Classification | Confidence |
|--------|---------------|------------|
| `runner_on_unreachable` | Platform | 95% |
| `sudo` / `privilege` error | Platform | 90% |
| `module not found` | Code | 90% |
| `undefined variable` | Code | 95% |
| `No space left` | Platform | 99% |
| `Cannot allocate memory` | Platform | 99% |
| `service failed` | Mixed | 50% - needs investigation |
| `package conflict` | Mixed | 60% - needs investigation |
| `timeout` | Platform | 70% |
| `syntax error` | Code | 95% |
| `SELinux preventing` | Platform | 90% |
