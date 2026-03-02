---
name: governed-job-launcher
description: |
  Execute governed job launches with check mode, approval gates, phased rollout, and rollback.

  Use when:
  - After deployment-risk-analyzer has classified the deployment risk
  - "Launch with check mode first", "Run the dry run"
  - "Execute the deployment" (after risk analysis)
  - "Rollback the failed job"

  NOT for: risk analysis (use deployment-risk-analyzer first) or troubleshooting (use job-failure-analyzer).
model: inherit
color: red
---

# Governed Job Launcher

## Prerequisites

**Required MCP Servers**:
- `aap-mcp-job-management` - Job launch, monitoring, events, relaunch

**Verification**: Run the `aap-mcp-validator` skill with `aap-mcp-job-management` before proceeding.

**IMPORTANT**: This skill assumes the `deployment-risk-analyzer` skill has already been executed and its risk assessment is available. Do NOT launch jobs without prior risk analysis for CRITICAL or HIGH risk targets.

## When to Use This Skill

Use this skill when:
- After `deployment-risk-analyzer` has completed risk assessment
- Risk level has been determined and governance controls are known
- User has been informed of risk and is ready to proceed

Do NOT use when:
- Risk analysis hasn't been performed yet (run `deployment-risk-analyzer` first)
- Troubleshooting a failed job (use `job-failure-analyzer` skill)
- Assessing platform readiness (use `governance-readiness-assessor` skill)

## Workflow

### Step 1: Consult Deployment Governance Documentation

**CRITICAL**: Document consultation MUST happen BEFORE any MCP tool invocations.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [deployment-governance.md](../../docs/aap/deployment-governance.md) using the Read tool to understand check mode execution, interpretation, phased rollout, and rollback patterns
2. **Output to user**: "I consulted [deployment-governance.md](docs/aap/deployment-governance.md) to understand Red Hat's check mode behavior, rollback patterns, and phased rollout strategy."

### Step 2: Execute Based on Risk Level

#### For CRITICAL / HIGH Risk: Check Mode First

**MCP Tool**: `job_templates_launch_create` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<template_id>"`
- `requestBody`:
  - `job_type`: `"check"`
  - `diff_mode`: `true`
  - `extra_vars`: (from user/template, if any)
  - `limit`: (if scoping to specific hosts)

Per Red Hat's *Job Templates documentation* (Ch. 9): The `job_type` field supports `"check"` mode for dry-run execution, and `diff_mode` shows what would change.

#### For MEDIUM Risk: Direct with Confirmation

Ask user for confirmation, then launch directly with `job_type: "run"`.

#### For LOW Risk: Direct Execution

Launch with `job_type: "run"` directly (user has already been informed by risk analyzer).

### Step 3: Monitor Job Progress

Poll job status until completion:

**MCP Tool**: `jobs_retrieve` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<job_id>"`

Poll every few seconds. Status values: `pending`, `waiting`, `running`, `successful`, `failed`, `error`, `canceled`.

### Step 4: Interpret Check Mode Results (CRITICAL/HIGH only)

After check mode completes, retrieve results:

**MCP Tool**: `jobs_job_host_summaries_list` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<check_mode_job_id>"`

**MCP Tool**: `jobs_job_events_list` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<check_mode_job_id>"`
- `page_size`: `100`

**Interpretation** (per deployment-governance.md):

| Host Summary | Meaning | Action |
|---|---|---|
| `failures > 0` | Tasks would fail | **STOP** -- report failures, do NOT proceed |
| `dark > 0` | Hosts unreachable | **STOP** -- connectivity issue |
| `changed > 0`, `failures = 0` | Changes would be applied successfully | Present findings, ask for approval |
| `ok > 0`, `changed = 0` | Already in desired state | Report: "No changes needed" |

**Shell/command module warning**: Per Ansible check mode documentation, `shell` and `command` modules are skipped in check mode. Warn user: "Tasks using shell/command modules were skipped and were NOT validated in this dry run."

**Output to user**:

```
## Check Mode Results — Job #[job_id]

**Status**: [successful/failed]

### Host Summary
| Host | OK | Changed | Failed | Unreachable | Skipped |
|---|---|---|---|---|---|
| [host] | [ok] | [changed] | [failures] | [dark] | [skipped] |

### Check Mode Findings
- [X] tasks would make changes
- [Y] tasks would fail
- [Z] tasks were skipped (shell/command — NOT validated)

### Recommendation
[Based on results: proceed / stop / investigate]

⚠️ Per Ansible check mode documentation: shell/command tasks were skipped and require separate validation.

**Proceed with full execution?** (yes/no)
```

### Step 5: Full Execution (After Approval)

#### Standard Execution (HIGH risk or below)

**MCP Tool**: `job_templates_launch_create` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<template_id>"`
- `requestBody`:
  - `job_type`: `"run"`
  - `extra_vars`: (same as check mode)

#### Phased Rollout (CRITICAL risk)

Per deployment-governance.md, CRITICAL risk deployments use phased rollout:

**Phase 1 - Canary**:
```json
{
  "id": "<template_id>",
  "requestBody": {
    "job_type": "run",
    "limit": "<canary_host>"
  }
}
```

Verify canary success via `jobs_job_host_summaries_list`. If `failures = 0`, proceed.

**Phase 2 - Expanded (25%)**:
```json
{
  "id": "<template_id>",
  "requestBody": {
    "job_type": "run",
    "limit": "<group>[0:25%]"
  }
}
```

Verify. If `failures = 0`, proceed.

**Phase 3 - Full Rollout**:
```json
{
  "id": "<template_id>",
  "requestBody": {
    "job_type": "run"
  }
}
```

**Health gate between phases**: Check `jobs_job_host_summaries_list` for `failures = 0` before proceeding to next phase. If ANY failures, STOP and report.

### Step 6: Post-Execution Summary

**MCP Tool**: `jobs_job_host_summaries_list` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<final_job_id>"`

Report only hosts with `changed > 0` or `failures > 0`:

```
## Deployment Summary — Job #[job_id]

**Status**: [successful/failed]
**Elapsed**: [time]

### Changed Hosts
| Host | Changed | Failed |
|---|---|---|
| [host] | [changed] | [failures] |

### Result
[X] hosts changed, [Y] hosts failed, [Z] hosts unchanged.
```

### Step 7: Rollback (If Failure)

If the job fails, offer rollback options per deployment-governance.md:

**Option 1 - Relaunch on failed hosts**:

**MCP Tool**: `jobs_relaunch_create` (from aap-mcp-job-management)
**Parameters**:
- `id`: `"<failed_job_id>"`
- `requestBody`:
  - `hosts`: `"failed"`
  - `credential_passwords`: `{}`

**Option 2 - Rollback playbook**: Launch a different template (if a rollback template exists).

**Option 3 - Revert to previous job**: Relaunch the last successful job.

## Dependencies

### Required MCP Servers
- `aap-mcp-job-management` - All job operations

### Required MCP Tools
- `job_templates_launch_create` (from job-management) - Launch jobs
- `jobs_retrieve` (from job-management) - Monitor progress
- `jobs_job_events_list` (from job-management) - Event details
- `jobs_job_host_summaries_list` (from job-management) - Host summaries
- `jobs_relaunch_create` (from job-management) - Rollback/relaunch

### Related Skills
- `deployment-risk-analyzer` - MUST run before this skill
- `aap-mcp-validator` - Prerequisite validation
- `execution-summary` - Audit trail after launch

### Reference Documentation
- [deployment-governance.md](../../docs/aap/deployment-governance.md) - Check mode, rollback, phased rollout patterns

## Critical: Human-in-the-Loop Requirements

This skill requires explicit user confirmation at the following steps:

1. **Before Full Execution** (CRITICAL/HIGH risk)
   - Display check mode results
   - Ask: "Check mode passed. Proceed with full execution?"
   - Wait for explicit "yes" or "proceed"

2. **Between Rollout Phases** (CRITICAL risk)
   - Display phase results
   - Ask: "Phase [N] succeeded on [X] hosts. Proceed to Phase [N+1]?"
   - Wait for confirmation

3. **Before Rollback**
   - Display failure summary
   - Ask: "Job failed on [X] hosts. Choose rollback option: (1) Relaunch on failed hosts, (2) Run rollback playbook, (3) Manual investigation"
   - Wait for user choice

**Never execute without approval** for CRITICAL or HIGH risk targets.

## Example Usage

**User**: "Deploy the security patch to production" (after risk analyzer identified CRITICAL risk)

**Agent**:
1. Reads deployment-governance.md
2. Launches check mode: `job_type: "check"`, `diff_mode: true`
3. Reports: "Check mode completed. 1 host would have 3 changes, 1 failure detected (dnf package not found). Per Ansible check mode documentation, dnf contacts repos and resolves dependencies in check mode — this failure is real."
4. Recommends: "STOP — check mode detected a failure. Do not proceed to full execution."
