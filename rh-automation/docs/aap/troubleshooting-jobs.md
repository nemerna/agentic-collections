---
title: AAP Job Troubleshooting Guide
category: aap
sources:
  - title: "Red Hat AAP 2.6 Troubleshooting Guide - Jobs"
    url: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs
    sections: "Common job failures, privilege escalation, module errors, connectivity"
    date_accessed: 2026-02-22
  - title: "Red Hat AAP 2.4 Troubleshooting Guide"
    url: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.4/html-single/troubleshooting_ansible_automation_platform/index
    sections: "Platform troubleshooting, job failures, host connectivity"
    date_accessed: 2026-02-22
tags: [troubleshooting, job-failures, errors, aap, debugging, forensics]
applies_to: [aap2.4, aap2.5, aap2.6]
semantic_keywords:
  - job failure analysis
  - AAP troubleshooting
  - privilege escalation timeout
  - module not found
  - host unreachable
  - connection timeout
  - ansible error
  - task failure
  - job event parsing
  - root cause analysis
use_cases:
  - forensic_troubleshooting
  - job_failure_analysis
  - error_classification
  - resolution_recommendation
related_docs:
  - references/error-classification.md
  - aap/job-launching-best-practices.md
last_updated: 2026-02-22
---

# AAP Job Troubleshooting Guide

## Overview

When AAP jobs fail, the root cause can stem from multiple sources: playbook logic errors, host platform issues, AAP configuration problems, or network connectivity failures. This guide provides systematic troubleshooting patterns derived from the official Red Hat AAP Troubleshooting Guide.

## When to Use This

- After a job failure when performing forensic analysis
- When classifying the root cause of a failure
- When determining whether the issue is platform-side or code-side
- When generating resolution recommendations

## Job Event Analysis

### Event Types and Their Meaning

AAP records events for every task execution. Key event types:

| Event Type | Description | Indicates |
|-----------|-------------|-----------|
| `runner_on_ok` | Task completed successfully, no changes | Healthy execution |
| `runner_on_changed` | Task completed with changes | Successful modification |
| `runner_on_failed` | Task execution failed | Code or platform error |
| `runner_on_unreachable` | Host could not be contacted | Network or SSH issue |
| `runner_on_skipped` | Task was skipped (condition not met) | Expected behavior |
| `runner_on_start` | Task started execution | Progress tracking |
| `runner_on_async_ok` | Async task completed | Long-running task success |
| `runner_on_async_failed` | Async task failed | Long-running task failure |
| `playbook_on_stats` | Play summary statistics | Final status |

### Extracting Failure Events

To identify the root cause, filter job events to failures:

```
For each event in job_events:
  IF event.event in ["runner_on_failed", "runner_on_unreachable"]:
    Extract:
      - host: event.host
      - task: event.task (or event.event_data.task)
      - role: event.role (if applicable)
      - error_message: event.event_data.res.msg
      - module: event.event_data.task_action
      - stdout: event.event_data.res.stdout (if available)
      - stderr: event.event_data.res.stderr (if available)
      - return_code: event.event_data.res.rc (if available)
```

### Failure Sequence Reconstruction

Reconstruct the failure sequence to understand cascade effects:

```
Timeline:
  T+0:00  Task "Gather Facts" → OK (all hosts)
  T+0:15  Task "Check disk space" → OK (all hosts)
  T+0:30  Task "Stop service" → OK (web-01, web-02) | FAILED (db-01)
  T+0:31  Task "Update packages" → SKIPPED (db-01, due to previous failure)
  T+0:45  Task "Start service" → OK (web-01, web-02) | SKIPPED (db-01)

Root cause: Task "Stop service" failed on db-01
Cascade: All subsequent tasks skipped on db-01
```

## Common Failure Patterns

### 1. Privilege Escalation Failures

**Symptoms**:
- Error: `"Missing sudo password"` or `"Timeout waiting for privilege escalation"`
- Event type: `runner_on_failed`
- Module: Any task with `become: true`

**Root Causes**:
- sudo password not configured in AAP Credential
- sudo timeout too low on target host (default: 5 minutes)
- sudoers file misconfigured (user not in sudoers)
- PAM module blocking sudo (e.g., expired password)

**Resolution (Platform Issue)**:
```
Per Red Hat AAP Troubleshooting Guide:

1. Verify AAP Machine Credential includes sudo password:
   - Resources → Credentials → [credential] → Privilege Escalation
   - Ensure "Privilege Escalation Password" is set

2. Increase sudo timeout on target host:
   - Edit /etc/sudoers: Defaults timestamp_timeout=30

3. Verify user is in sudoers:
   - Check: grep <username> /etc/sudoers /etc/sudoers.d/*
   - Add if missing: echo "<username> ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/<username>

4. Check PAM configuration:
   - Verify: pam_tally2 --user=<username>
   - Reset if locked: pam_tally2 --user=<username> --reset
```

### 2. Module Not Found

**Symptoms**:
- Error: `"The module <module_name> was not found in configured module paths"`
- Error: `"No module named 'ansible.builtin.<module>'"`
- Event type: `runner_on_failed`

**Root Causes**:
- Collection not installed in Execution Environment
- Incorrect module FQCN (Fully Qualified Collection Name)
- Execution Environment image missing required collections

**Resolution (Code Issue)**:
```
Per Red Hat AAP Best Practices:

1. Verify collection is installed in Execution Environment:
   - Check EE image: podman run <ee-image> ansible-galaxy collection list
   - If missing: Add to requirements.yml in project

2. Use correct FQCN:
   - Wrong: yum (bare module name)
   - Right: ansible.builtin.yum (FQCN)

3. Update Execution Environment:
   - Add collection to EE definition file
   - Rebuild EE: ansible-builder build
```

### 3. Host Unreachable

**Symptoms**:
- Error: `"Failed to connect to the host via ssh"` or `"Connection timed out"`
- Event type: `runner_on_unreachable`

**Root Causes**:
- SSH port not open or blocked by firewall
- SSH key not authorized on target
- DNS resolution failure
- Network partition or routing issue
- Host is powered off or crashed

**Resolution (Platform Issue)**:
```
Systematic diagnostic:

1. Verify host is alive:
   - ping <hostname>
   - If no response: Check host power state, hypervisor status

2. Verify SSH connectivity:
   - ssh -v -i <key> <user>@<host>
   - If refused: Check firewall (iptables -L, firewall-cmd --list-all)
   - If timeout: Check routing, security groups, network ACLs

3. Verify AAP credential:
   - Ensure Machine Credential SSH key matches authorized_keys on host
   - Test: ssh -i /path/to/key <user>@<host>

4. Verify DNS:
   - nslookup <hostname>
   - If fails: Check /etc/hosts or DNS configuration
```

### 4. Service Failed to Start

**Symptoms**:
- Error: `"Job for <service>.service failed"` or `"Failed to start <service>"`
- Event type: `runner_on_failed`
- Module: `ansible.builtin.systemd` or `ansible.builtin.service`

**Root Causes**:
- Configuration syntax error in service config file
- Port already in use by another process
- Missing dependency (library, binary, config file)
- Insufficient disk space for service data/logs
- SELinux denying service access

**Resolution**:
```
Diagnostic sequence:

1. Check service status and logs:
   - systemctl status <service>
   - journalctl -xeu <service> --no-pager -n 50

2. Check for port conflicts:
   - ss -tlnp | grep <port>
   - If conflict: Stop conflicting service or change port

3. Check disk space:
   - df -h /var /tmp /var/log
   - If full: Clear old logs, temporary files

4. Check SELinux:
   - ausearch -m AVC -ts recent
   - If denied: restorecon -Rv /path/to/service/files

5. Validate configuration:
   - <service> -t  (for nginx, apache)
   - <service> --check-config (service-specific)
```

### 5. Package Dependency Conflicts

**Symptoms**:
- Error: `"Problem: package <pkg> conflicts with..."` or `"Error: Nothing to do"`
- Event type: `runner_on_failed`
- Module: `ansible.builtin.dnf` or `ansible.builtin.yum`

**Root Causes**:
- Conflicting package versions already installed
- Repository providing wrong version
- Third-party repos conflicting with RHEL repos

**Resolution (Code/Platform Issue)**:
```
Per Red Hat Package Management docs:

1. Check current installed version:
   - rpm -q <package>
   - dnf list installed <package>

2. Check available versions:
   - dnf list available <package>
   - dnf repoquery <package>

3. Resolve conflicts:
   - dnf check
   - dnf distro-sync (align all packages)
   - If third-party: dnf --disablerepo=<third-party-repo> update <package>

4. Check subscription:
   - subscription-manager status
   - subscription-manager repos --list-enabled
```

### 6. Timeout Errors

**Symptoms**:
- Error: `"command exceeded timeout"` or `"Timeout waiting for..."` or `"Async task timed out"`
- Event type: `runner_on_failed`

**Root Causes**:
- Long-running command exceeding default timeout (usually 300s)
- Network latency causing connection drops
- Target host under heavy load
- Large file transfers exceeding async poll timeout

**Resolution**:
```
1. Increase task timeout:
   - Add to task: timeout: 600 (for shell/command)
   - For async: async: 3600, poll: 30

2. Check host performance:
   - Retrieve host facts: CPU load, memory usage, disk I/O
   - If resource-constrained: Scale resources or reduce batch size

3. Network optimization:
   - Use pipelining: [ssh_connection] pipelining = True
   - Use persistent connections: [connection] persistent_command_timeout = 60
```

## Host Fact Correlation

### Correlating Failures with System State

After identifying the failing host, retrieve system facts to determine if the failure is due to platform drift:

| Fact | Check | Indicates |
|------|-------|-----------|
| `ansible_distribution_major_version` | Matches supported versions (7, 8, 9) | OS compatibility |
| `ansible_mounts[*].size_available` | Root/var/tmp have >10% free | Disk space |
| `ansible_memtotal_mb` vs `ansible_memfree_mb` | >10% memory available | Memory pressure |
| `ansible_processor_vcpus` and `ansible_processor_count` | CPU count reasonable | Compute capacity |
| `ansible_uptime_seconds` | Not recently rebooted mid-job | System stability |
| `ansible_selinux.status` | "enforcing" or "permissive" | SELinux state |
| `ansible_pkg_mgr` | "dnf" for RHEL 8/9, "yum" for RHEL 7 | Package manager |

### Platform Drift Indicators

Platform drift occurs when the host configuration has deviated from expected baseline:

```
Platform Drift Detection:
- OS version mismatch: Expected RHEL 9, found RHEL 7 (EOL)
- Disk usage >90%: Critical - may cause write failures
- Memory <5% free: Service startup may fail
- Unsupported Python version: Ansible modules may fail
- SELinux disabled when expected enforcing: Security non-compliance
- Missing subscriptions: Package updates will fail
```

## Resolution Path Decision Tree

```
Start: Job #N failed
  │
  ├─ Event type: runner_on_unreachable
  │   → PLATFORM ISSUE: Network/SSH connectivity
  │   → Check: Host alive? SSH port open? Key authorized?
  │
  ├─ Event type: runner_on_failed
  │   │
  │   ├─ Error contains "sudo" or "privilege"
  │   │   → PLATFORM ISSUE: Privilege escalation
  │   │   → Check: Credential config, sudoers, PAM
  │   │
  │   ├─ Error contains "module" and "not found"
  │   │   → CODE ISSUE: Missing collection/module
  │   │   → Check: EE image, requirements.yml, FQCN
  │   │
  │   ├─ Error contains "service" and "failed"
  │   │   → INVESTIGATE: Could be either
  │   │   → Check: Config syntax, port conflict, disk, SELinux
  │   │
  │   ├─ Error contains "conflict" or "dependency"
  │   │   → MIXED: Package management issue
  │   │   → Check: Repos, installed versions, subscriptions
  │   │
  │   ├─ Error contains "timeout"
  │   │   → PLATFORM ISSUE: Resource or network constraint
  │   │   → Check: Host load, network latency, task timeout
  │   │
  │   └─ Other
  │       → INVESTIGATE: Read full error message and stdout/stderr
  │       → Consult Ansible module documentation
  │
  └─ Playbook completed but unexpected results
      → CODE ISSUE: Logic error in playbook
      → Check: Conditionals, variable values, template rendering
```

## Related Documentation

- [Error Classification](../references/error-classification.md) - Detailed error taxonomy
- [Job Launching Best Practices](job-launching-best-practices.md) - Pre-launch validation
- [Deployment Governance](deployment-governance.md) - Governance patterns that prevent failures

## Quick Reference

| Error Pattern | Category | Most Common Root Cause |
|--------------|----------|----------------------|
| `sudo password` | Platform | Missing credential config |
| `module not found` | Code | Missing collection in EE |
| `unreachable` | Platform | SSH/Network connectivity |
| `service failed` | Mixed | Config error or disk full |
| `dependency conflict` | Mixed | Third-party repo conflict |
| `timeout` | Platform | Resource constraint |
| `permission denied` | Platform | SELinux or file permissions |
| `template error` | Code | Jinja2 syntax or missing variable |
| `vault decrypt` | Platform | Wrong vault password/credential |
