---
name: job-failure-analyzer
description: |
  **CRITICAL**: This skill must be used for ALL job failure analysis. DO NOT read job events directly without forensic analysis.

  Use this skill when users request:
  - Analyzing a failed job: "job #502 failed", "why did the deployment fail?", "analyze the failed job"
  - Understanding job errors: "what went wrong with job X?", "show me the failure details"
  - Error classification: "was it a script error or host issue?", "is this a platform problem?"

  This skill performs: job event extraction, failure event identification, error pattern matching, error classification (platform vs code), and failure sequence reconstruction.

  DO NOT use this skill when:
  - Deploying to production → Use `governance-deployer` agent
  - Checking host system facts → Use `host-fact-inspector` skill
  - Getting resolution recommendations → Use `troubleshooting-advisor` skill

  For comprehensive troubleshooting (analysis + facts + resolution), use the `forensic-troubleshooter` agent which orchestrates this skill with host-fact-inspector and troubleshooting-advisor.

  **IMPORTANT**: ALWAYS use this skill instead of reading job events directly.
model: inherit
color: blue
---

# Job Failure Analyzer Skill

Deep forensic analysis of failed AAP jobs. Extracts job events, identifies failing tasks, classifies errors as platform or code issues, and reconstructs the failure sequence.

**Integration with Forensic Troubleshooter Agent**: The forensic-troubleshooter agent orchestrates this skill as Step 2 (Analyze Failure) after MCP validation. For standalone failure analysis, invoke this skill directly.

## Prerequisites

**Required MCP Servers**: `aap-mcp-job-management` ([setup guide](../../README.md))

**Required MCP Tools**:
- `jobs_retrieve` (from aap-mcp-job-management) - Get job details and status
- `jobs_job_events_list` (from aap-mcp-job-management) - List job events
- `jobs_stdout_retrieve` (from aap-mcp-job-management) - Get job stdout (optional)

### Prerequisite Validation

**CRITICAL**: Before executing any operations, invoke the [mcp-aap-validator](../mcp-aap-validator/SKILL.md) skill to verify MCP server availability.

**Validation freshness**: Can skip if already validated in this session.

## When to Use This Skill

**Use this skill directly when you need**:
- Quick failure analysis without full troubleshooting workflow
- Error classification (platform vs code) for a specific job
- Job event summary for reporting purposes

**Use the forensic-troubleshooter agent when you need**:
- Full root cause analysis (events + host facts + documentation + resolution)
- Correlation of failure with system state
- Resolution recommendations with Red Hat documentation backing

## Workflow

### Step 1: Retrieve Job Details

**MCP Tool**: `jobs_retrieve` (from aap-mcp-job-management)

**Parameters**:
- `id`: Job ID from user request
  - Example: `502`

**Expected Output**: Job metadata including:
- `status` - Job final status (failed, error, successful, canceled)
- `job_template` - Template used
- `inventory` - Target inventory
- `limit` - Host limit applied
- `started` - Start timestamp
- `finished` - End timestamp
- `elapsed` - Duration in seconds
- `failed` - Whether job failed (boolean)
- `launch_type` - How job was launched (manual, scheduled, etc.)

**Output to user**:
```
Job #<id> Details
━━━━━━━━━━━━━━━━

Status: <status>
Template: "<template_name>" (ID: <template_id>)
Inventory: "<inventory_name>"
Limit: <limit or "none">
Started: <timestamp>
Duration: <elapsed> seconds
Launch Type: <launch_type>
```

### Step 2: Extract Job Events

**CRITICAL**: Document consultation MUST happen BEFORE event analysis.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) using the Read tool to understand job event types and failure patterns
2. **Output to user**: "I consulted [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) to understand AAP job event analysis patterns."

**MCP Tool**: `jobs_job_events_list` (from aap-mcp-job-management)

**Parameters**:
- `id`: Job ID
- `page_size`: `200` (retrieve all events for thorough analysis)

**Event Parsing**:

Categorize events and extract failure details:

```
For each event:
  CASE event.event:
    "runner_on_failed":
      → Extract: host, task, module, error_message, stdout, stderr, return_code
      → Add to failed_events[]
      → Flag for error classification

    "runner_on_unreachable":
      → Extract: host, error_message
      → Add to unreachable_events[]
      → Immediately classify as PLATFORM ISSUE

    "runner_on_changed":
      → Extract: host, task
      → Add to changed_events[] (for context)

    "runner_on_ok":
      → Count: ok_count++

    "runner_on_skipped":
      → If preceded by failure on same host: mark as cascade skip
      → Add to skipped_events[]

    "playbook_on_stats":
      → Extract final statistics
```

### Step 3: Failure Sequence Reconstruction

Reconstruct the timeline of events to understand cascade effects:

```
Failure Timeline:
━━━━━━━━━━━━━━━━

T+<time>  [<host>] Task "<task_1>" → OK
T+<time>  [<host>] Task "<task_2>" → OK
T+<time>  [<host>] Task "<task_3>" → FAILED ← Root cause
T+<time>  [<host>] Task "<task_4>" → SKIPPED (cascade from task_3 failure)
T+<time>  [<host>] Task "<task_5>" → SKIPPED (cascade)

Root Cause: Task "<task_3>" failed on host "<host>"
Cascade Effect: <N> subsequent tasks skipped on <host>
```

### Step 4: Error Classification

**CRITICAL**: Document consultation MUST happen BEFORE classification.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [error-classification.md](../../docs/references/error-classification.md) using the Read tool to understand platform vs code error classification
2. **Output to user**: "I consulted [error-classification.md](../../docs/references/error-classification.md) to classify the error as platform or code issue."

**Classification Logic**:

Apply the error classification taxonomy:

```
For each failed/unreachable event:

  IF event.event == "runner_on_unreachable":
    Classification: PLATFORM ISSUE (95% confidence)
    Category: Network/Connectivity

  ELIF error contains "sudo" or "privilege":
    Classification: PLATFORM ISSUE (90% confidence)
    Category: Authentication/Privilege Escalation

  ELIF error contains "module" and "not found":
    Classification: CODE ISSUE (90% confidence)
    Category: Missing Collection/Module

  ELIF error contains "undefined variable" or "syntax error":
    Classification: CODE ISSUE (95% confidence)
    Category: Template/Logic Error

  ELIF error contains "No space left" or "Cannot allocate memory":
    Classification: PLATFORM ISSUE (99% confidence)
    Category: Resource Exhaustion

  ELIF error contains "service failed" or "failed to start":
    Classification: MIXED (50% confidence - needs investigation)
    Category: Service Failure
    → Recommend: host-fact-inspector for correlation

  ELIF error contains "conflict" or "dependency":
    Classification: MIXED (60% confidence - needs investigation)
    Category: Package Management
    → Recommend: Check repos and installed versions

  ELIF error contains "timeout":
    Classification: PLATFORM ISSUE (70% confidence)
    Category: Resource/Network Constraint

  ELIF error contains "SELinux" or "AVC":
    Classification: PLATFORM ISSUE (90% confidence)
    Category: SELinux Policy

  ELSE:
    Classification: NEEDS INVESTIGATION
    → Recommend: host-fact-inspector + troubleshooting-advisor
```

### Step 5: Failure Analysis Report

**Output**:
```
Job Failure Analysis Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━

Job #<id>: <status>
Template: "<template_name>"
Duration: <elapsed>s

Event Summary:
  OK: <count> | Changed: <count> | Failed: <count> | Unreachable: <count> | Skipped: <count>

Root Cause Analysis:
━━━━━━━━━━━━━━━━━━━━

Classification: <PLATFORM ISSUE | CODE ISSUE | MIXED>
Confidence: <percentage>%
Category: <category>

Failing Task: "<task_name>"
Module: <module_name>
Host(s): <host_list>
Error: <error_message>

<If stdout/stderr available>
stdout: <relevant_stdout>
stderr: <relevant_stderr>
</If>

Failure Sequence:
<timeline from Step 3>

Affected Hosts:
| Host | Status | Error Type | Error Summary |
|------|--------|-----------|---------------|
| <host1> | Failed | <type> | <summary> |
| <host2> | Unreachable | Platform | <summary> |

<If PLATFORM ISSUE>
🔧 This appears to be a Platform Issue (infrastructure/environment).
   Responsible: Infrastructure / Platform team
   The playbook logic is likely correct, but the environment prevented execution.
</If>

<If CODE ISSUE>
🐛 This appears to be a Code Issue (playbook/automation logic).
   Responsible: Automation Developer
   The environment is likely healthy, but the automation code has a bug.
</If>

<If MIXED>
🔍 This requires further investigation to determine root cause.
   Recommendation: Inspect host facts for affected systems.
</If>

Next Steps:
1. <Based on classification>
2. <Recommended action>
3. For detailed resolution: Use the forensic-troubleshooter agent
```

## Dependencies

### Required MCP Servers
- `aap-mcp-job-management` - Job details, events, stdout

### Required MCP Tools
- `jobs_retrieve` (from aap-mcp-job-management) - Get job details
  - Parameters: id (int)
  - Returns: Job metadata, status, timestamps
- `jobs_job_events_list` (from aap-mcp-job-management) - List job events
  - Parameters: id (int), page_size (int)
  - Returns: List of job events with task details and results
- `jobs_stdout_retrieve` (from aap-mcp-job-management) - Get job stdout (optional)
  - Parameters: id (int)
  - Returns: Raw job stdout text

### Related Skills
- `mcp-aap-validator` - **PREREQUISITE** - Validates AAP MCP before operations
- `host-fact-inspector` - **NEXT STEP** - Correlates failures with host system state
- `troubleshooting-advisor` - **NEXT STEP** - Provides resolution recommendations

### Reference Documentation
- [troubleshooting-jobs.md](../../docs/aap/troubleshooting-jobs.md) - AAP job event types and failure patterns
- [error-classification.md](../../docs/references/error-classification.md) - Platform vs code error taxonomy
