---
name: troubleshooting-advisor
description: |
  Documentation-backed troubleshooting guidance and resolution recommendations.

  Use this skill when:
  - After failure analysis and fact inspection: "how do I fix this error?", "what does Red Hat recommend?"
  - Getting resolution recommendations: "what's the fix for privilege escalation timeout?"
  - Looking up known issues: "is this a known AAP issue?"
  - Classifying resolution path: "is this a platform fix or a code fix?"

  DO NOT use this skill when:
  - Analyzing job events → Use `job-failure-analyzer` first
  - Checking host facts → Use `host-fact-inspector` first
  - The full troubleshooting workflow → Use `forensic-troubleshooter` agent
model: inherit
color: blue
---

# Troubleshooting Advisor Skill

Generates documentation-backed resolution recommendations by consulting the Red Hat AAP Troubleshooting Guide and error classification taxonomy. Matches error patterns to known issues and provides resolution paths differentiated by platform vs code responsibility.

**Integration with Forensic Troubleshooter Agent**: The forensic-troubleshooter agent orchestrates this skill as Step 4 (Advise Resolution) after failure analysis and host fact inspection.

## Prerequisites

This skill primarily uses documentation consultation (no MCP tools required for resolution generation). However, it benefits from output of previous skills:
- `job-failure-analyzer` output: error classification, failing task, error message
- `host-fact-inspector` output: host health status, platform drift findings

## When to Use This Skill

**Use this skill directly when you need**:
- Quick resolution lookup for a known error pattern
- Documentation reference for a specific AAP issue
- Resolution path determination (platform vs code fix)

**Use the forensic-troubleshooter agent when you need**:
- Complete troubleshooting workflow from job failure to resolution
- Correlation-based resolution (not just pattern matching)

## Workflow

### Step 1: Gather Context

**Input**: Collect findings from previous skills:

```
From job-failure-analyzer:
  - error_classification: PLATFORM | CODE | MIXED
  - error_category: Network, Authentication, Resource, etc.
  - error_message: "<specific error text>"
  - failing_task: "<task name>"
  - failing_module: "<module name>"
  - affected_hosts: [<host_list>]

From host-fact-inspector (if available):
  - host_health: HEALTHY | DEGRADED | CRITICAL
  - platform_drift: [<drift_findings>]
  - error_correlation: "<fact that likely caused error>"
  - correlation_confidence: <percentage>
```

### Step 2: Consult Documentation

**CRITICAL**: Document consultation MUST happen BEFORE generating recommendations.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) using the Read tool to match the error against known failure patterns and resolution steps
2. **Output to user**: "I consulted [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) to match the error against known AAP failure patterns."

**Document Consultation** (REQUIRED - Execute SECOND):
1. **Action**: Read [error-classification.md](../../docs/references/error-classification.md) using the Read tool to determine the resolution template and priority
2. **Output to user**: "I consulted [error-classification.md](../../docs/references/error-classification.md) to determine the resolution path and priority."

### Step 3: Match Error to Known Patterns

Match the error message and context against the documented failure patterns:

**Pattern Matching Logic**:
```
1. Privilege Escalation Failures:
   Match: error contains "sudo", "privilege", "password is required"
   Resolution: Check AAP Credential, sudoers config, PAM
   Doc Section: troubleshooting-jobs.md → "Privilege Escalation Failures"

2. Module Not Found:
   Match: error contains "module", "not found", "No module named"
   Resolution: Check EE image, collection requirements, FQCN
   Doc Section: troubleshooting-jobs.md → "Module Not Found"

3. Host Unreachable:
   Match: event == "runner_on_unreachable"
   Resolution: Check SSH, firewall, DNS, host power state
   Doc Section: troubleshooting-jobs.md → "Host Unreachable"

4. Service Failed to Start:
   Match: error contains "service", "failed", "Job for"
   Resolution: Check config syntax, port conflicts, disk, SELinux
   Doc Section: troubleshooting-jobs.md → "Service Failed to Start"

5. Package Dependency Conflicts:
   Match: error contains "conflict", "dependency", "Nothing to do"
   Resolution: Check repos, installed versions, subscription
   Doc Section: troubleshooting-jobs.md → "Package Dependency Conflicts"

6. Timeout Errors:
   Match: error contains "timeout", "exceeded timeout", "Async task timed out"
   Resolution: Increase timeout, check host performance, use async
   Doc Section: troubleshooting-jobs.md → "Timeout Errors"
```

### Step 4: Generate Resolution Recommendation

**For Platform Issues**:
```
🔧 Resolution: Platform Issue - <category>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Affected Host(s): <host_list>
Error: <error_message>
Confidence: <percentage>%

Root Cause:
  <Specific finding from error analysis and host fact correlation>

Resolution Steps:
  Per Red Hat AAP Troubleshooting Guide:

  1. <Specific step 1 from documentation>
  2. <Specific step 2 from documentation>
  3. <Specific step 3 from documentation>

  📖 Reference: <Red Hat documentation URL>

<If host fact correlation available>
Supporting Evidence:
  Host fact: <specific fact that confirms root cause>
  Finding: <interpretation>
</If>

Verification:
  After applying the fix, re-run the job to verify:
  - Template: "<template_name>"
  - Limit to affected hosts: "<host_list>"

Prevention:
  To prevent this issue in the future:
  - <preventive measure 1>
  - <preventive measure 2>
```

**For Code Issues**:
```
🐛 Resolution: Code Issue - <category>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Failing Task: "<task_name>"
Module: <module_name>
Error: <error_message>

Root Cause:
  <Specific code issue identified>

Resolution Steps:
  1. <Code change required>
  2. <How to test the fix>
  3. Commit change to project repo
  4. Sync project in AAP (Projects → <project> → Sync)
  5. Re-run the job

  📖 Reference: <Ansible module documentation URL>

Code Fix Example:
  <Before/after code snippet if applicable>

Verification:
  1. Run in Check Mode first to verify fix
  2. Then execute full run
```

**For Mixed Issues**:
```
🔍 Resolution: Mixed Issue - Requires Investigation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Error: <error_message>
Classification Confidence: <percentage>% (below threshold for definitive classification)

Possible Root Causes:

Possibility 1: Platform Issue (<percentage>% likely)
  <platform explanation>
  Fix: <platform fix steps>

Possibility 2: Code Issue (<percentage>% likely)
  <code explanation>
  Fix: <code fix steps>

Recommended Approach:
  1. Start with the more likely root cause
  2. Apply fix and re-test
  3. If still failing, try the alternative fix

📖 References:
  - <Red Hat doc URL 1>
  - <Ansible doc URL 2>
```

### Step 5: Summary and Next Steps

**Output**:
```
Troubleshooting Summary
━━━━━━━━━━━━━━━━━━━━━━━

Job #<id>: <status>
Classification: <PLATFORM | CODE | MIXED>
Root Cause: <one-line summary>
Resolution: <one-line fix summary>

Skills Consulted:
  ✓ job-failure-analyzer → Error identified and classified
  ✓ host-fact-inspector → Host facts correlated (if applicable)
  ✓ troubleshooting-advisor → Resolution generated

Documents Consulted:
  📖 troubleshooting-jobs.md → Matched error to known pattern
  📖 error-classification.md → Determined resolution path

Recommended Actions:
  1. <Primary fix action>
  2. <Verification action>
  3. <Prevention action>

Would you like me to:
- Help implement the fix?
- Re-run the job after fixing?
- Generate an execution summary for audit purposes?
```

## Dependencies

### Required MCP Servers
None required directly (this skill primarily consults documentation)

### Related Skills
- `job-failure-analyzer` - **PROVIDES INPUT** - Error classification and details
- `host-fact-inspector` - **PROVIDES INPUT** - Host health and fact correlation
- `mcp-aap-validator` - **INDIRECT** - Used by preceding skills
- `execution-summary` - **OPTIONAL** - Generate audit report after troubleshooting

### Reference Documentation
- [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) - Known failure patterns and resolution steps
- [error-classification.md](../../docs/references/error-classification.md) - Error taxonomy and resolution templates
- [job-launching-best-practices.md](../../docs/aap/job-launching-best-practices.md) - Prevention through governance

## Example Usage

### Example 1: Privilege Escalation Failure (Platform Issue)

**Context**: job-failure-analyzer found "Missing sudo password" on host db-01

**Skill Response**:
```
I consulted troubleshooting-jobs.md to match this against known AAP failure patterns.
I consulted error-classification.md to determine the resolution path.

🔧 Resolution: Platform Issue - Privilege Escalation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Affected Host: db-01
Error: "Missing sudo password"
Confidence: 90%

Root Cause:
  The AAP Machine Credential does not include a sudo password,
  and the target host requires a password for privilege escalation.

Resolution Steps:
  Per Red Hat AAP Troubleshooting Guide:

  1. Navigate to AAP Web UI → Resources → Credentials
  2. Edit the Machine Credential used by this template
  3. In "Privilege Escalation" section, set the sudo password
  4. Alternatively, configure passwordless sudo on the target:
     echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/ansible

  📖 Reference: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs

Verification:
  Re-run Job Template "DB-Maintenance" with limit: "db-01"
```

### Example 2: Disk Full + Service Failure (Mixed, Resolved by Facts)

**Context**: job-failure-analyzer found "Service failed to start" (MIXED).
host-fact-inspector found /var at 98% used on db-01.

**Skill Response**:
```
🔧 Resolution: Platform Issue - Resource Exhaustion (confirmed by host facts)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Affected Host: db-01
Error: "Job for postgresql.service failed"
Confidence: 95% (elevated from 50% by host fact correlation)

Root Cause:
  PostgreSQL service failed to start because /var is at 98% capacity.
  The database cannot write transaction logs or temporary files.

Supporting Evidence:
  Host fact: ansible_mounts[/var].size_available = 850 MB (2% free)
  Normal: >10% free space required for PostgreSQL operation

Resolution Steps:
  1. Free disk space on /var:
     - Clear old logs: find /var/log -name "*.log" -mtime +30 -delete
     - Compress logs: journalctl --vacuum-size=100M
     - Remove old packages: dnf clean all

  2. After freeing space, restart the service:
     systemctl restart postgresql

  3. Set up monitoring to prevent recurrence:
     - Configure logrotate for application logs
     - Set disk usage alerts at 80% threshold

  📖 Reference: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs

Prevention:
  - Add pre-flight disk space check to playbook
  - Configure monitoring for /var usage
  - Consider LVM volume expansion
```
