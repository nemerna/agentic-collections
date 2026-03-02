---
name: governance-readiness-assessor
description: |
  Assess AAP platform governance readiness across 7 domains using Red Hat best practices.

  Use when:
  - "Is my AAP ready for production?"
  - "Audit my platform governance"
  - "Check governance readiness"
  - "What should I fix before deploying?"
  - "Assess my AAP configuration"

  NOT for: deploying jobs (use governance-deployer agent) or troubleshooting failures (use forensic-troubleshooter agent).
model: inherit
color: red
---

# Governance Readiness Assessor

## Prerequisites

**Required MCP Servers**: All 6 AAP MCP servers
- `aap-mcp-job-management`
- `aap-mcp-inventory-management`
- `aap-mcp-configuration`
- `aap-mcp-security-compliance`
- `aap-mcp-system-monitoring`
- `aap-mcp-user-management`

**Verification**: Run the `aap-mcp-validator` skill with all 6 servers before proceeding.

## When to Use This Skill

Use this skill when:
- User asks to assess or audit AAP governance readiness
- User asks if their AAP is ready for production
- Before a first production deployment (as part of governance-assessor agent)
- User asks what needs to be fixed in their AAP configuration

Do NOT use when:
- User wants to deploy a specific job (use `deployment-risk-analyzer` + `governed-job-launcher` skills)
- User wants to troubleshoot a failed job (use `job-failure-analyzer` skill)
- User only wants MCP connectivity validation (use `aap-mcp-validator` skill)

## Workflow

### Step 1: Consult Governance Readiness Documentation

**CRITICAL**: Document consultation MUST happen BEFORE any MCP tool invocations.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [governance-readiness.md](../../docs/aap/governance-readiness.md) using the Read tool to understand the 7-domain assessment framework, Red Hat source citations, decision tables, and output template
2. **Output to user**: "I consulted [governance-readiness.md](docs/aap/governance-readiness.md) to understand Red Hat's governance best practices for the 7-domain assessment framework."

### Step 2: Query All 6 MCP Servers

Execute all queries to gather assessment data. Run these in parallel where possible.

**Domain 1 - Workflow Governance**:

**MCP Tool**: `workflow_job_templates_list` (from aap-mcp-job-management)
**Parameters**:
- `page_size`: `100`

**MCP Tool**: `job_templates_list` (from aap-mcp-job-management)
**Parameters**:
- `page_size`: `100`

**Domain 2 - Notification Coverage**:

**MCP Tool**: `notification_templates_list` (from aap-mcp-configuration)
**Parameters**:
- `page_size`: `100`

**Domain 3 - Access Control (RBAC)**:

**MCP Tool**: `users_list` (from aap-mcp-user-management)
**Parameters**:
- `page_size`: `100`

**MCP Tool**: `teams_list` (from aap-mcp-user-management)
**Parameters**:
- `page_size`: `100`

**MCP Tool**: `role_user_assignments_list` (from aap-mcp-user-management)
**Parameters**:
- `page_size`: `100`

**MCP Tool**: `role_team_assignments_list` (from aap-mcp-user-management)
**Parameters**:
- `page_size`: `100`

**Domain 4 - Credential Security**:

**MCP Tool**: `credentials_list` (from aap-mcp-security-compliance)
**Parameters**:
- `page_size`: `100`

**MCP Tool**: `credential_types_list` (from aap-mcp-security-compliance)
**Parameters**:
- `page_size`: `100`

**Domain 5 - Execution Environments**:

**MCP Tool**: `execution_environments_list` (from aap-mcp-configuration)
**Parameters**:
- `page_size`: `100`

**Domain 6 - Workload Isolation**:

**MCP Tool**: `instance_groups_list` (from aap-mcp-system-monitoring)
**Parameters**:
- `page_size`: `100`

**Domain 7 - Audit Trail**:

**MCP Tool**: `activity_stream_list` (from aap-mcp-system-monitoring)
**Parameters**:
- `page_size`: `10`

**Bonus - External Authentication**:

**MCP Tool**: `authenticators_list` (from aap-mcp-user-management)
**Parameters**:
- `page_size`: `100`

### Step 3: Assess Each Domain

For EACH domain, follow the assessment pattern from the governance-readiness.md document:

1. **Lead with the Red Hat quote** from the document
2. **Report what was found** from the MCP query results
3. **Apply the decision table** from the document to determine PASS/GAP/WARN
4. **Provide the recommendation** with Red Hat source citation

**CRITICAL**: Every finding MUST include the Red Hat documentation citation. The audience must SEE where each recommendation comes from. This is the proof that the agent embeds official Red Hat knowledge, not arbitrary rules.

**Output format per domain** (from governance-readiness.md):

```
### Domain [N]: [Name] — [PASS/GAP/WARN]

Per Red Hat's *[Source Document]* ([Chapter/Section]):
> "[Direct quote from Red Hat documentation]"

**Finding**: [What the MCP query revealed]
**Recommendation**: [Action with Red Hat source citation]
```

### Step 4: Generate Summary Report

Produce the full Governance Readiness Report following the output template in governance-readiness.md. Include:

1. Assessment date and AAP instance identifier
2. Per-domain findings with Red Hat citations
3. Summary table with all domain statuses
4. Overall score: X PASS, Y WARN, Z GAP out of 8 domains

### Step 5: Offer Remediation

For any domains with GAP or WARN status, offer to remediate using MCP write tools where available:

| Domain | Remediation Available via MCP? | Tool |
|---|---|---|
| Workflow Governance | No (manual) | N/A |
| Notification Coverage | **Yes** | `notification_templates_create` |
| Access Control (RBAC) | **Yes** | `teams_create`, `role_user_assignments_create` |
| Credential Security | **Yes** | `credentials_create` |
| Execution Environments | **Yes** | `execution_environments_create` |
| Workload Isolation | **Yes** | `instance_groups_create` |
| Audit Trail | No (automatic) | N/A |
| External Authentication | **Yes** | `authenticators_create` |

**Human-in-the-Loop**: Before creating or modifying any resource, present the planned change and ask for explicit user approval.

## Dependencies

### Required MCP Servers
- `aap-mcp-job-management` - Workflow and job template data
- `aap-mcp-inventory-management` - Inventory data
- `aap-mcp-configuration` - Notifications, EEs, settings
- `aap-mcp-security-compliance` - Credentials and credential types
- `aap-mcp-system-monitoring` - Instance groups and activity stream
- `aap-mcp-user-management` - Users, teams, roles, authenticators

### Required MCP Tools
- `workflow_job_templates_list`, `job_templates_list` (from job-management)
- `notification_templates_list` (from configuration)
- `execution_environments_list` (from configuration)
- `users_list`, `teams_list`, `role_user_assignments_list`, `role_team_assignments_list`, `authenticators_list` (from user-management)
- `credentials_list`, `credential_types_list` (from security-compliance)
- `instance_groups_list`, `activity_stream_list` (from system-monitoring)

### Related Skills
- `aap-mcp-validator` - Prerequisite: validate all 6 servers first
- `execution-summary` - Generate audit trail after assessment

### Reference Documentation
- [governance-readiness.md](../../docs/aap/governance-readiness.md) - The 7-domain assessment reference

## Critical: Human-in-the-Loop Requirements

This skill requires explicit user confirmation at the following steps:

1. **Before Remediation Actions**
   - Display the planned change (e.g., "Create team 'automation-operators'")
   - Ask: "Should I create this resource to address the gap?"
   - Wait for explicit user confirmation

2. **Never auto-remediate**: Always present findings first and wait for user decision on remediation

## Example Usage

**User**: "Assess my AAP platform's governance readiness"

**Agent**:

1. Reads governance-readiness.md
2. Reports: "I consulted governance-readiness.md to understand Red Hat's governance best practices for the 7-domain assessment framework."
3. Validates all 6 MCP servers via aap-mcp-validator
4. Queries each server with the tools listed above
5. Produces the full Governance Readiness Report with Red Hat citations per domain
6. Offers remediation for any gaps found
