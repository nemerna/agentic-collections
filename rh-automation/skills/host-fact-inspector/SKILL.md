---
name: host-fact-inspector
description: |
  Correlate job failures with host system facts to determine platform drift and resource issues.

  Use this skill when:
  - After job failure analysis identifies affected hosts: "check the system facts for the failed hosts"
  - Investigating platform drift: "is the host healthy?", "check disk space on server-01"
  - Correlating errors with system state: "why is the service failing on this host?"
  - Validating host meets requirements: "is this host running supported RHEL?"

  DO NOT use this skill when:
  - Analyzing job events → Use `job-failure-analyzer` first
  - Getting resolution recommendations → Use `troubleshooting-advisor` after this skill
  - Deploying to production → Use `governance-deployer` agent
model: inherit
color: blue
---

# Host Fact Inspector Skill

Correlates job failures with host system facts to determine if failures are caused by platform drift, resource exhaustion, or environmental issues. Retrieves ansible_facts for affected hosts and produces a health assessment.

**Integration with Forensic Troubleshooter Agent**: The forensic-troubleshooter agent orchestrates this skill as Step 3 (Inspect Host Facts) after job failure analysis.

## Prerequisites

**Required MCP Servers**: `aap-mcp-inventory-management` ([setup guide](../../README.md))

**Required MCP Tools**:
- `hosts_list` (from aap-mcp-inventory-management) - Search for hosts
- `hosts_retrieve` (from aap-mcp-inventory-management) - Get host details
- `hosts_ansible_facts_retrieve` (from aap-mcp-inventory-management) - Get cached ansible_facts

### Prerequisite Validation

**CRITICAL**: Before executing, verify that [mcp-aap-validator](../mcp-aap-validator/SKILL.md) has passed in this session.

## When to Use This Skill

**Use this skill directly when you need**:
- Standalone host health check
- Quick fact lookup for a specific host
- Platform drift detection for a set of hosts

**Use the forensic-troubleshooter agent when you need**:
- Full troubleshooting (failure analysis → fact inspection → resolution)
- Correlation between specific error messages and host state

## Workflow

### Step 1: Identify Affected Hosts

**Input**: Host names or IDs from job failure analysis (job-failure-analyzer output)

If host names are provided by user or previous skill:
- Use them directly

If only a job ID is available:
- The job-failure-analyzer skill should have identified the failing hosts
- Extract host names from the failure analysis output

### Step 2: Retrieve Host Facts

**CRITICAL**: Document consultation MUST happen BEFORE fact analysis.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) using the Read tool, specifically the "Host Fact Correlation" section, to understand which facts indicate platform drift
2. **Output to user**: "I consulted [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) to understand host fact correlation patterns."

**For each affected host:**

**MCP Tool**: `hosts_list` (from aap-mcp-inventory-management)

**Parameters**:
- `search`: Host name or hostname pattern
  - Example: `"db-01"`
- `page_size`: `5`

**Then**: `hosts_ansible_facts_retrieve` (from aap-mcp-inventory-management)

**Parameters**:
- `id`: Host ID from hosts_list result

**Expected Output**: Cached ansible_facts including:
- `ansible_distribution` - OS distribution (e.g., "RedHat")
- `ansible_distribution_major_version` - OS major version (e.g., "9")
- `ansible_mounts` - Filesystem mounts with space info
- `ansible_memtotal_mb` - Total memory
- `ansible_memfree_mb` - Free memory
- `ansible_processor_vcpus` - CPU count
- `ansible_uptime_seconds` - System uptime
- `ansible_selinux` - SELinux status
- `ansible_pkg_mgr` - Package manager (dnf/yum)
- `ansible_python` - Python version info

**Note**: Facts may be cached and not reflect real-time state. The "last modified" timestamp indicates when facts were last gathered.

### Step 3: Health Assessment

**CRITICAL**: Document consultation MUST happen BEFORE health assessment.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [error-classification.md](../../docs/references/error-classification.md) using the Read tool, specifically the "Correlation with Host Facts" and "Host Health Assessment Template" sections
2. **Output to user**: "I consulted [error-classification.md](../../docs/references/error-classification.md) to understand host health assessment criteria."

**Analyze facts against health criteria**:

```
For each host:

  OS Version Check:
    IF ansible_distribution != "RedHat":
      FLAG: "Not a RHEL system"
    ELIF ansible_distribution_major_version == "7":
      FLAG: "RHEL 7 - End of Maintenance Support (EOL risk)"
    ELIF ansible_distribution_major_version in ["8", "9"]:
      OK: "Supported RHEL version"

  Disk Space Check:
    FOR each mount in ansible_mounts:
      percent_used = (mount.size_total - mount.size_available) / mount.size_total * 100
      IF percent_used > 95:
        CRITICAL: "<mount_point> at <percent>% - CRITICAL"
      ELIF percent_used > 90:
        WARNING: "<mount_point> at <percent>% - WARNING"
      ELSE:
        OK: "<mount_point> at <percent>%"

  Memory Check:
    percent_used = (ansible_memtotal_mb - ansible_memfree_mb) / ansible_memtotal_mb * 100
    IF percent_used > 95:
      CRITICAL: "Memory at <percent>% - OOM risk"
    ELIF percent_used > 85:
      WARNING: "Memory at <percent>%"
    ELSE:
      OK: "Memory at <percent>%"

  SELinux Check:
    IF ansible_selinux.status == "disabled":
      WARNING: "SELinux disabled (expected: enforcing)"
    ELIF ansible_selinux.mode == "permissive":
      WARNING: "SELinux permissive (expected: enforcing)"
    ELSE:
      OK: "SELinux enforcing"

  Package Manager Check:
    IF ansible_distribution_major_version in ["8", "9"] AND ansible_pkg_mgr != "dnf":
      WARNING: "Expected dnf on RHEL 8/9, found <pkg_mgr>"
    ELIF ansible_distribution_major_version == "7" AND ansible_pkg_mgr != "yum":
      WARNING: "Expected yum on RHEL 7, found <pkg_mgr>"
    ELSE:
      OK: "Package manager correct for RHEL version"
```

### Step 4: Correlate with Error

If the job-failure-analyzer has identified specific errors, correlate with facts:

```
Error Correlation Matrix:
━━━━━━━━━━━━━━━━━━━━━━━━

Error: "Service failed to start"
  + Disk /var at 98% → LIKELY CAUSE: Disk full preventing service data write
  + Memory at 97% → POSSIBLE CAUSE: OOM killing service process

Error: "Module not found"
  + Python 2.7 on RHEL 7 → LIKELY CAUSE: Module requires Python 3

Error: "Permission denied"
  + SELinux enforcing → LIKELY CAUSE: SELinux policy blocking access

Error: "Package update failed"
  + RHEL 7 → CHECK: Is task using dnf module? (should use yum on RHEL 7)
```

### Step 5: Host Health Report

**Output**:
```
Host Health Assessment
━━━━━━━━━━━━━━━━━━━━━━

Host: <hostname> (ID: <host_id>)
Last Facts Update: <timestamp>

System:
  OS: RHEL <version> (<Supported|EOL>)
  Uptime: <days> days
  Python: <version>
  Package Manager: <dnf|yum>
  SELinux: <status>

Resources:
  CPU: <vcpus> vCPUs
  Memory: <total> MB total, <free> MB free (<percent>% used) <OK|WARNING|CRITICAL>
  Disk /:    <available> GB free (<percent>% used) <OK|WARNING|CRITICAL>
  Disk /var: <available> GB free (<percent>% used) <OK|WARNING|CRITICAL>
  Disk /tmp: <available> GB free (<percent>% used) <OK|WARNING|CRITICAL>

Health Status: <HEALTHY|DEGRADED|CRITICAL>

<If correlating with error>
Error Correlation:
  Error: "<error_message>"
  Finding: <fact that likely caused the error>
  Confidence: <percentage>%
  Classification: <PLATFORM ISSUE confirmed | Needs further investigation>
</If>

<If platform drift detected>
⚠️ Platform Drift Detected:
  - <drift_finding_1>
  - <drift_finding_2>

  Recommendation: <remediation_action>
</If>

Next Steps:
1. <Based on findings>
2. For resolution recommendations: Use troubleshooting-advisor skill
```

## Dependencies

### Required MCP Servers
- `aap-mcp-inventory-management` - Host details and ansible facts

### Required MCP Tools
- `hosts_list` (from aap-mcp-inventory-management) - Search hosts
  - Parameters: search (string), page_size (int)
  - Returns: List of matching hosts
- `hosts_retrieve` (from aap-mcp-inventory-management) - Get host details
  - Parameters: id (int)
  - Returns: Host metadata
- `hosts_ansible_facts_retrieve` (from aap-mcp-inventory-management) - Get cached ansible facts
  - Parameters: id (int)
  - Returns: ansible_facts dictionary

### Related Skills
- `mcp-aap-validator` - **PREREQUISITE** - Validates AAP MCP before operations
- `job-failure-analyzer` - **PROVIDES INPUT** - Identifies affected hosts and errors
- `troubleshooting-advisor` - **NEXT STEP** - Generates resolution recommendations

### Reference Documentation
- [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) - Host fact correlation patterns
- [error-classification.md](../../docs/references/error-classification.md) - Fact-based root cause detection
