---
title: AAP Job Launching Best Practices
category: aap
sources:
  - title: "Red Hat AAP Controller User Guide - Launching Jobs"
    url: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/controller-job-templates#launching-job-templates
    sections: "Launching job templates, extra variables, limit, check mode"
    date_accessed: 2026-02-22
  - title: "Ansible Automation Controller Best Practices"
    url: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/assembly-controller-best-practices
    sections: "Best practices for job templates, credentials, inventories"
    date_accessed: 2026-02-22
tags: [aap, job-templates, launching, check-mode, limit, extra-vars, governance]
applies_to: [aap2.5, aap2.6]
semantic_keywords:
  - job template launch
  - check mode dry run
  - limit host subset
  - extra variables
  - production deployment safety
  - credential management
  - job launch parameters
  - survey variables
use_cases:
  - governance_deployment
  - check_mode_execution
  - limit_enforcement
  - variable_sanitization
related_docs:
  - aap/deployment-governance.md
  - references/error-classification.md
last_updated: 2026-02-22
---

# AAP Job Launching Best Practices

## Overview

Launching jobs in Ansible Automation Platform requires careful consideration of target scope, variable security, and execution mode. This document codifies Red Hat best practices for safe, governed job launches.

## When to Use This

- Before launching any job template via AAP MCP
- When validating deployment parameters for production targets
- When determining check mode vs run mode strategy
- When reviewing extra_vars for security compliance

## Check Mode (Dry Run)

### What Check Mode Does

Check mode (`--check`) runs the playbook without making changes. Modules that support check mode report what *would* change. This is critical for production safety.

**AAP Controller**: When launching a job template, set `job_type: "check"` to execute in check mode.

### When to Use Check Mode

**Always recommend check mode when:**
- Target inventory contains production hosts
- Deploying to sensitive environments (PCI, HIPAA, financial)
- Running a template for the first time against a target
- Extra variables have been modified from defaults
- The playbook performs package updates or service restarts

**Check mode is optional when:**
- Target is a development/test environment
- Running a well-tested template with no parameter changes
- Gathering facts only (no changes expected)

### Check Mode Limitations

Not all Ansible modules support check mode. Modules that use `shell`, `command`, `raw`, or `script` do not support check mode natively. When these modules are present:

```yaml
# Modules that do NOT support check mode natively:
- shell: "systemctl restart httpd"    # Will be SKIPPED in check mode
- command: "/usr/local/bin/deploy.sh" # Will be SKIPPED in check mode
- raw: "reboot"                       # Will be SKIPPED in check mode

# Workaround: Use check_mode: false to force execution even in check mode
- name: Gather disk usage (safe to run always)
  shell: "df -h"
  check_mode: false
  changed_when: false
```

### Launching in Check Mode via AAP MCP

```
MCP Tool: job_templates_launch_retrieve (from aap-mcp-job-management)

Parameters:
  id: <job_template_id>       # Required: Template ID to launch
  job_type: "check"           # Execute as dry run
  limit: "<host_pattern>"     # Optional: Limit scope
  extra_vars:                 # Optional: Override variables
    key: "value"
```

### Interpreting Check Mode Results

After check mode execution, analyze job events:

| Event Status | Meaning | Action |
|-------------|---------|--------|
| `ok` | Task would not change anything | No action needed |
| `changed` | Task WOULD make a change | Review carefully |
| `skipped` | Task condition not met or module doesn't support check mode | Verify intent |
| `failed` | Task would fail (syntax error, missing dependency) | Fix before real run |

**Key insight**: Focus only on `changed` events to understand what the deployment will do.

## Limit (Host Scope Control)

### Why Limit Matters

The `limit` parameter restricts job execution to a subset of hosts in the inventory. This is critical for:

1. **Phased rollouts**: Deploy to `us-east` group first, then `us-west`
2. **Blast radius control**: Limit initial deployment to 1-2 hosts
3. **Testing in production**: Target a canary host before full fleet
4. **Emergency response**: Patch only the most critical hosts first

### Limit Patterns

```bash
# Single host
limit: "web-server-01"

# Host group
limit: "us-east"

# Multiple groups (intersection)
limit: "webservers:&us-east"

# Exclude hosts
limit: "all:!db-servers"

# Percentage of hosts
limit: "webservers[0:2]"  # First 3 hosts only

# Pattern matching
limit: "web-*"
```

### Limit Best Practices

1. **Always suggest limit for production**: When the target inventory is production, recommend limiting to a subset first
2. **Start small**: Begin with 1-2 hosts, verify success, then expand
3. **Group-based limits**: Use AAP inventory groups rather than individual host names
4. **Document the rollout plan**: Record which groups will be targeted in which order

## Extra Variables Security

### The Plain-Text Secret Problem

Extra variables (`extra_vars`) are a common vector for credential exposure. Users frequently pass passwords, API keys, and tokens as plain-text extra variables:

```yaml
# DANGEROUS - Plain-text secrets in extra_vars
extra_vars:
  db_password: "SuperSecret123!"      # Plain-text password
  api_key: "sk-abc123xyz789"           # Plain-text API key
  ssh_private_key: "-----BEGIN RSA..." # Private key material
```

### Detection Patterns

Scan extra_vars for these patterns to detect potential secrets:

| Pattern | Indicator | Risk |
|---------|-----------|------|
| `password`, `passwd`, `pass` | Password field | Critical |
| `secret`, `token`, `key` | Secret/API key | Critical |
| `-----BEGIN` | Certificate/key material | Critical |
| `sk-`, `api_key`, `apikey` | API key prefix | High |
| `credential`, `auth` | Authentication data | High |
| Base64-encoded strings (>40 chars) | Encoded secrets | Medium |

### Secure Alternatives

When secrets are detected in extra_vars, recommend:

1. **AAP Credentials**: Use AAP's built-in credential management
   - Machine credentials for SSH keys
   - Custom credential types for API keys
   - Vault credentials for encrypted variables

2. **Ansible Vault**: Encrypt sensitive variables
   ```bash
   ansible-vault encrypt_string 'SuperSecret123!' --name 'db_password'
   ```

3. **Survey Variables**: Use AAP surveys with password-type fields (masked input, encrypted storage)

4. **External Secret Management**: HashiCorp Vault, CyberArk, etc. via lookup plugins

### Enforcement Response

When plain-text secrets are detected:

```
⛔ BLOCKED: Plain-text secret detected in extra_vars

Found potentially sensitive variable: "db_password"
Value appears to contain a plain-text password.

Secure alternatives:
1. Use an AAP Credential (recommended)
   - Navigate to Resources → Credentials → Add
   - Select appropriate credential type
   - Reference in job template

2. Use Ansible Vault encryption
   - Encrypt the value: ansible-vault encrypt_string '<value>' --name 'db_password'

3. Use a Survey with password field
   - Add survey to job template
   - Set field type to "Password" (masked + encrypted)

Would you like to proceed without the secret (remove it from extra_vars)?
```

## Job Launch Governance Checklist

Before launching any job, validate:

| Check | Risk Level | Action |
|-------|-----------|--------|
| Inventory contains "prod", "pci", "secure" | HIGH | Require check mode + limit |
| Extra vars contain passwords/secrets | CRITICAL | Block and require AAP Credential |
| Template has never been run against this inventory | MEDIUM | Recommend check mode |
| Template modifies system packages | MEDIUM | Recommend check mode |
| Template performs reboots | HIGH | Require maintenance window |
| Template targets >50 hosts | MEDIUM | Recommend phased rollout |
| Template uses `become: true` | MEDIUM | Verify privilege escalation |

## Post-Execution Analysis

### Changed-Only Summary

After job execution, filter events to show only meaningful changes:

```
Job #1234 Execution Summary (Changed Tasks Only)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total Events: 247
Changed: 5 | OK: 230 | Skipped: 10 | Failed: 2

Changed Tasks:
1. [web-01] Update httpd package → httpd-2.4.57-8.el9
2. [web-01] Restart httpd service
3. [web-02] Update httpd package → httpd-2.4.57-8.el9
4. [web-02] Restart httpd service
5. [web-01] Update SSL certificate

Failed Tasks:
1. [db-01] Update postgresql → FAILED (dependency conflict)
2. [db-01] Restart postgresql → SKIPPED (previous task failed)
```

### Event Filtering Logic

```
For each job_event:
  IF event.event == "runner_on_changed":
    INCLUDE in Changed summary
  ELIF event.event == "runner_on_failed":
    INCLUDE in Failed summary with error detail
  ELIF event.event == "runner_on_unreachable":
    INCLUDE in Unreachable summary
  ELSE:
    EXCLUDE from summary (reduces noise)
```

## Related Documentation

- [Deployment Governance Patterns](deployment-governance.md) - Governance workflow patterns
- [Error Classification](../references/error-classification.md) - Error taxonomy for post-execution analysis
- [AAP Troubleshooting](troubleshooting-jobs.md) - When jobs fail

## Quick Reference

| Parameter | Purpose | When Required |
|-----------|---------|---------------|
| `job_type: "check"` | Dry run execution | Production targets |
| `limit` | Restrict host scope | >10 hosts or production |
| `extra_vars` | Override variables | Sanitize before use |
| `credentials` | Authentication | Always use AAP Credentials |
| `diff_mode: true` | Show file diffs | Config changes |
