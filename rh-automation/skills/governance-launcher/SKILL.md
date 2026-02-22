---
name: governance-launcher
description: |
  **CRITICAL**: This skill must be used for governed job execution. DO NOT use raw MCP tools to launch jobs directly in production.

  Use this skill when users request:
  - Launching a job with governance controls: "launch with check mode first", "run the dry run"
  - Executing after safety checks pass: invoked by governance-deployer agent after deployment-safety-checker
  - Running in check mode: "run this in check mode", "do a dry run"
  - Post-execution analysis: "show me what changed", "summarize the job results"

  This skill handles: check mode execution, dry-run analysis, user confirmation, full execution, and changed-only post-execution summaries.

  DO NOT use this skill when:
  - Safety checks haven't been performed → Use `deployment-safety-checker` first
  - Troubleshooting a failed job → Use `job-failure-analyzer` skill
  - Validating AAP MCP → Use `mcp-aap-validator` skill

  **IMPORTANT**: This skill assumes safety checks have already passed. Always run deployment-safety-checker first for production targets.
model: inherit
color: red
---

# Governance Launcher Skill

Executes AAP jobs with full governance controls: check mode (dry run) first, dry-run result analysis, explicit user confirmation, full execution, and changed-only post-execution summaries.

**Integration with Governance Deployer Agent**: The governance-deployer agent orchestrates this skill as Step 3 (Governed Execution) after safety checks pass.

## Prerequisites

**Required MCP Servers**: `aap-mcp-job-management` ([setup guide](../../README.md))

**Required MCP Tools**:
- `job_templates_launch_retrieve` (from aap-mcp-job-management) - Launch job from template
- `jobs_retrieve` (from aap-mcp-job-management) - Get job status
- `jobs_job_events_list` (from aap-mcp-job-management) - List job events

### Prerequisite Validation

**CRITICAL**: Before executing any operations, verify that:
1. [mcp-aap-validator](../mcp-aap-validator/SKILL.md) has passed in this session
2. [deployment-safety-checker](../deployment-safety-checker/SKILL.md) has assessed the deployment (for production targets)

## When to Use This Skill

**Use this skill directly when you need**:
- Governed job launch with check mode
- Post-execution event analysis and summary
- Standalone check mode execution and results interpretation

**Use the governance-deployer agent when you need**:
- Full end-to-end workflow (MCP validation → safety check → governed launch)

## Workflow

### Step 1: Check Mode Execution (Dry Run)

**CRITICAL**: Document consultation MUST happen BEFORE execution.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [job-launching-best-practices.md](../../docs/aap/job-launching-best-practices.md) using the Read tool to understand check mode execution and result interpretation
2. **Output to user**: "I consulted [job-launching-best-practices.md](../../docs/aap/job-launching-best-practices.md) to understand check mode execution patterns."

**MCP Tool**: `job_templates_launch_retrieve` (from aap-mcp-job-management)

**Parameters**:
- `id`: Job template ID (from safety checker output)
  - Example: `42`
- `job_type`: `"check"` (execute as dry run - this is the key governance control)
- `limit`: Limit string from safety checker recommendation
  - Example: `"us-east[0:1]"` (canary: first 2 hosts)
- `extra_vars`: Sanitized extra variables (secrets removed)
  - Example: `{"app_version": "2.1.0", "deploy_env": "production"}`

**Expected Output**: Job ID and initial status

**Output to user**:
```
🔍 Launching Check Mode (Dry Run)...

Job ID: #<job_id>
Template: "<template_name>"
Mode: Check (Dry Run)
Limit: "<limit_value>"
```

### Step 2: Monitor Job Status

**MCP Tool**: `jobs_retrieve` (from aap-mcp-job-management)

**Parameters**:
- `id`: Job ID from Step 1

**Poll Strategy**:
```
WHILE job.status NOT IN ["successful", "failed", "error", "canceled"]:
  Wait 5 seconds
  Poll jobs_retrieve(id=job_id)
  Report status transition to user:
    "Job #<id> status: <status>"
```

**Status transitions**:
- `pending` → `waiting` → `running` → `successful` (happy path)
- `pending` → `waiting` → `running` → `failed` (task failure)
- `pending` → `error` (launch error)
- `running` → `canceled` (user canceled)

### Step 3: Analyze Dry-Run Results

**MCP Tool**: `jobs_job_events_list` (from aap-mcp-job-management)

**Parameters**:
- `id`: Job ID from Step 1
- `page_size`: `200` (retrieve all events)

**Analysis Logic**:

Parse events and categorize:
```
changed_events = []
failed_events = []
skipped_events = []
ok_count = 0

For each event:
  IF event.event == "runner_on_changed":
    changed_events.append({
      host: event.host,
      task: event.event_data.task,
      module: event.event_data.task_action,
      details: event.event_data.res
    })
  ELIF event.event == "runner_on_failed":
    failed_events.append({
      host: event.host,
      task: event.event_data.task,
      error: event.event_data.res.msg
    })
  ELIF event.event == "runner_on_skipped":
    skipped_events.append(...)
  ELIF event.event == "runner_on_ok":
    ok_count += 1
```

**Dry-Run Summary Output**:
```
Check Mode (Dry Run) Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Job #<id> completed in <duration>

Summary: <changed> changed | <ok_count> ok | <skipped> skipped | <failed> failed

Tasks That WOULD Change:
1. [<host>] <task_name> → <description of change>
2. [<host>] <task_name> → <description of change>
...

<If failed tasks exist>
⚠️ Tasks That WOULD Fail:
1. [<host>] <task_name> → <error_message>
...
Fix these issues before proceeding with full execution.
</If>

<If no changed tasks>
ℹ️ No changes detected. The target systems are already in the desired state.
</If>
```

### Step 4: Request Execution Confirmation

**CRITICAL**: Human-in-the-loop is MANDATORY before full execution.

**Confirmation Request**:
```
❓ Review the dry-run results above.

This deployment will:
- Apply <changed_count> changes to <host_count> hosts
- Limit: "<limit_value>"
- Require reboot: <if detected from events>

Options:
- "proceed" - Execute the full deployment with the same parameters
- "expand" - Proceed and expand scope (remove or widen limit)
- "modify" - Change parameters before executing
- "abort" - Cancel the deployment

Please confirm your choice.
```

**Wait for explicit user approval. Do NOT proceed without it.**

### Step 5: Full Execution

**Only execute after receiving explicit "proceed" or "expand" confirmation.**

**MCP Tool**: `job_templates_launch_retrieve` (from aap-mcp-job-management)

**Parameters**:
- `id`: Same job template ID
- `job_type`: `"run"` (full execution, not check mode)
- `limit`: Same limit as dry run (unless user chose "expand")
  - If "expand": Use widened limit or remove limit
- `extra_vars`: Same sanitized variables

**Output to user**:
```
🚀 Launching Full Execution...

Job ID: #<job_id>
Template: "<template_name>"
Mode: Run (Full Execution)
Limit: "<limit_value>"
```

### Step 6: Monitor and Summarize Execution

**Monitor**: Same polling strategy as Step 2

**Post-Execution Summary** (Changed-Only, Noise Reduction):

**MCP Tool**: `jobs_job_events_list` (from aap-mcp-job-management)

**Parameters**:
- `id`: Job ID from Step 5
- `page_size`: `200`

**Changed-Only Summary**:
```
Deployment Complete
━━━━━━━━━━━━━━━━━━

Job #<id> completed: <status>
Duration: <time>

Summary: <changed> changed | <ok> ok | <skipped> skipped | <failed> failed

Changed Tasks (what actually changed):
1. [<host>] <task_name> → <change_description>
2. [<host>] <task_name> → <change_description>
...

<If failed>
⚠️ Failed Tasks:
1. [<host>] <task_name> → <error_message>

Recommendation: Use the forensic-troubleshooter agent to analyze failures.
</If>

<If all succeeded>
✅ All tasks completed successfully.
</If>

Next Steps:
- Verify deployment: Check application health
- Expand scope: "Proceed to deploy to the next group"
- Investigate failures: "Analyze why task X failed on host Y"
```

## Critical: Human-in-the-Loop Requirements

This skill performs execution on AAP systems. **Explicit confirmation is REQUIRED**.

1. **After Check Mode**: Present dry-run results and ask for confirmation
2. **Before Full Execution**: Wait for explicit "proceed"
3. **Before Scope Expansion**: Confirm new scope with user
4. **Never auto-execute**: Even if risk is LOW, still present results before execution

## Dependencies

### Required MCP Servers
- `aap-mcp-job-management` - Job template launch, status tracking, event analysis

### Required MCP Tools
- `job_templates_launch_retrieve` (from aap-mcp-job-management) - Launch job
  - Parameters: id (int), job_type (string: "run" or "check"), limit (string), extra_vars (object)
  - Returns: Job ID, initial status
- `jobs_retrieve` (from aap-mcp-job-management) - Get job status
  - Parameters: id (int)
  - Returns: Job status, timestamps, execution details
- `jobs_job_events_list` (from aap-mcp-job-management) - List job events
  - Parameters: id (int), page_size (int)
  - Returns: List of job events with task details, host results

### Related Skills
- `deployment-safety-checker` - **PREREQUISITE** - Must pass before governed launch
- `mcp-aap-validator` - **PREREQUISITE** - Must validate AAP MCP first
- `job-failure-analyzer` - **ON FAILURE** - Analyze if execution fails
- `execution-summary` - **OPTIONAL** - Generate audit report after completion

### Reference Documentation
- [job-launching-best-practices.md](../../docs/aap/job-launching-best-practices.md) - Check mode, post-execution analysis
- [deployment-governance.md](../../docs/aap/deployment-governance.md) - Governance workflow patterns

## Example Usage

### Example: Full Governance Launch Flow

**Context**: Safety checker has approved deployment with CRITICAL risk governance

**Skill Flow**:
```
1. Launch check mode: job_type="check", limit="us-east[0:1]"
   → Job #1234 started, monitoring...
   → Job #1234 completed: successful

2. Dry-run analysis:
   "3 tasks would change on 2 hosts:
    - [web-01] Update httpd → 2.4.57
    - [web-01] Restart httpd
    - [web-02] Update httpd → 2.4.57"

3. User confirms: "proceed"

4. Full execution: job_type="run", limit="us-east[0:1]"
   → Job #1235 started, monitoring...
   → Job #1235 completed: successful

5. Changed-only summary:
   "3 changes applied on 2 hosts:
    ✓ [web-01] Updated httpd to 2.4.57
    ✓ [web-01] Restarted httpd service
    ✓ [web-02] Updated httpd to 2.4.57

    ✅ All tasks completed successfully.

    Next: Expand to full us-east group?"
```
