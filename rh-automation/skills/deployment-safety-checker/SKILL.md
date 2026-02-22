---
name: deployment-safety-checker
description: |
  **CRITICAL**: This skill must be used before ANY production or sensitive deployment. DO NOT launch jobs directly without safety checks.

  Use this skill when users request:
  - Deploying to production or sensitive environments: "deploy to production", "push to prod", "release to production"
  - Checking deployment safety: "is this deployment safe?", "validate the deployment target"
  - Reviewing deployment parameters before launch: "check these extra_vars", "is this inventory safe?"

  This skill analyzes: inventory risk level, extra_vars for plain-text secrets, scope appropriateness, and recommends governance controls (check mode, limit enforcement).

  DO NOT use this skill when users request:
  - Troubleshooting a failed job → Use `job-failure-analyzer` skill
  - Just launching a job without governance → Still use this skill first if targeting production
  - Validating AAP MCP connectivity → Use `mcp-aap-validator` skill

  **IMPORTANT**: ALWAYS use this skill before `governance-launcher` for production targets.
model: inherit
color: red
---

# Deployment Safety Checker Skill

Comprehensive pre-deployment safety analysis that acts as a Change Control gatekeeper. This skill validates that deployments are safe before any job execution.

**Integration with Governance Deployer Agent**: The governance-deployer agent orchestrates this skill as Step 2 (Safety Check) after MCP validation. For standalone safety checks, invoke this skill directly.

## Prerequisites

**Required MCP Servers**: `aap-mcp-job-management`, `aap-mcp-inventory-management` ([setup guide](../../README.md))

**Required MCP Tools**:
- `job_templates_list` (from aap-mcp-job-management) - Search job templates
- `job_templates_retrieve` (from aap-mcp-job-management) - Get template details
- `inventories_list` (from aap-mcp-inventory-management) - List inventories
- `inventories_retrieve` (from aap-mcp-inventory-management) - Get inventory details
- `hosts_list` (from aap-mcp-inventory-management) - List hosts in inventory

### Prerequisite Validation

**CRITICAL**: Before executing any operations, invoke the [mcp-aap-validator](../mcp-aap-validator/SKILL.md) skill to verify MCP server availability.

**Validation freshness**: Can skip if already validated in this session. See [Validation Freshness Policy](../mcp-aap-validator/SKILL.md#validation-freshness-policy).

**Handle validation result**:
- **If validation PASSED**: Continue with safety analysis
- **If validation PARTIAL**: Warn user and ask to proceed
- **If validation FAILED**: Stop execution, provide setup instructions

## When to Use This Skill

**Use this skill directly when you need**:
- Standalone safety assessment of a deployment request
- Inventory risk classification without launching
- Extra_vars security audit
- Scope validation for a planned deployment

**Use the governance-deployer agent when you need**:
- End-to-end governed deployment (safety check → check mode → execution → summary)
- Automated workflow from request to completion

## Workflow

### Step 1: Resolve Job Template

**Action**: Identify the target job template from the user's request.

**MCP Tool**: `job_templates_list` (from aap-mcp-job-management)

**Parameters**:
- `search`: Search term extracted from user request (e.g., "Web-App-v2", "nginx-deploy")
  - Example: `"Web-App-v2"`
- `page_size`: `10` (retrieve top matches)

**Expected Output**: List of matching job templates with ID, name, inventory, project

**If no templates found**:
```
❌ No job template found matching "<search_term>"

Available job templates (showing first 10):
[list from job_templates_list with page_size: 10]

Please specify the exact template name or ID.
```

### Step 2: Retrieve Template Details

**MCP Tool**: `job_templates_retrieve` (from aap-mcp-job-management)

**Parameters**:
- `id`: Job template ID from Step 1

**Expected Output**: Complete template metadata including:
- `inventory` - Target inventory ID
- `extra_vars` - Default extra variables
- `ask_variables_on_launch` - Whether variables can be overridden
- `ask_limit_on_launch` - Whether limit can be set
- `ask_credential_on_launch` - Whether credentials can be changed
- `become_enabled` - Whether privilege escalation is used

### Step 3: Inventory Risk Classification

**CRITICAL**: Document consultation MUST happen BEFORE risk classification.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [deployment-governance.md](../../docs/aap/deployment-governance.md) using the Read tool to understand inventory risk classification patterns
2. **Output to user**: "I consulted [deployment-governance.md](../../docs/aap/deployment-governance.md) to understand inventory risk classification."

**MCP Tool**: `inventories_retrieve` (from aap-mcp-inventory-management)

**Parameters**:
- `id`: Inventory ID from the job template

**Risk Classification Logic**:

Apply the risk classification from the documentation:

```
HIGH_RISK_PATTERNS: prod, production, pci, hipaa, financial, secure, compliance, regulated, critical
MEDIUM_RISK_PATTERNS: staging, pre-prod, preprod, uat, qa-prod
LOW_RISK_PATTERNS: dev, development, sandbox, lab, demo

Classify based on inventory name matching these patterns.
```

**Risk Assessment Output**:

For CRITICAL risk:
```
⚠️ HIGH-RISK DEPLOYMENT DETECTED

Target inventory: "<inventory_name>" (Risk: CRITICAL)
Matched pattern: "<pattern>" in inventory name

Required governance:
1. ✅ Check Mode execution first (MANDATORY)
2. ✅ Limit to host subset (MANDATORY)
3. ✅ Extra variables sanitization (MANDATORY)
4. ✅ Explicit user approval (MANDATORY)

Recommendation: Start with a canary deployment (1-2 hosts)
```

For HIGH risk:
```
⚠️ Sensitive environment detected

Target inventory: "<inventory_name>" (Risk: HIGH)

Recommended governance:
1. ✅ Check Mode execution first (RECOMMENDED)
2. ✅ Limit to host subset (RECOMMENDED)
3. ✅ Extra variables sanitization (MANDATORY)
```

For MEDIUM/LOW risk:
```
Target inventory: "<inventory_name>" (Risk: LOW)
No additional governance required.
```

### Step 4: Scope Assessment

**MCP Tool**: `hosts_list` (from aap-mcp-inventory-management)

**Parameters**:
- `inventory`: Inventory ID
- `page_size`: `100` (get host count)

**Scope Assessment**:
```
IF host_count > 50:
  RECOMMEND phased rollout (batch of 10-20 hosts)
  SUGGEST limit parameter
ELIF host_count > 10:
  SUGGEST limit to verify on small subset first
ELSE:
  PROCEED with full scope
```

**Output**:
```
Scope Assessment:
- Total hosts in inventory: <count>
- Groups: <group_list>
- Recommendation: <phased/limited/full>

Suggested limit: "<group_name>[0:1]" (first 2 hosts of <group_name>)
```

### Step 5: Extra Variables Sanitization

**CRITICAL**: Document consultation MUST happen BEFORE variable scanning.

**Document Consultation** (REQUIRED - Execute FIRST):
1. **Action**: Read [job-launching-best-practices.md](../../docs/aap/job-launching-best-practices.md) using the Read tool to understand extra variables security patterns
2. **Output to user**: "I consulted [job-launching-best-practices.md](../../docs/aap/job-launching-best-practices.md) to understand extra variables security."

**Scan Extra Variables**:

Check the template's `extra_vars` and any user-provided overrides for plain-text secrets:

```
Secret Detection Patterns:
- Key names: password, passwd, pass, secret, token, key, credential, auth, api_key, apikey
- Value patterns: "-----BEGIN" (certificate/key material)
- Value patterns: Strings matching API key formats (sk-, pk-, etc.)
- Value patterns: Base64-encoded strings >40 characters

For each detected pattern:
  FLAG as potential plain-text secret
  RECOMMEND using AAP Credential instead
```

**If secrets detected**:
```
⛔ BLOCKED: Plain-text secret detected in extra_vars

Found potentially sensitive variable(s):
- "<variable_name>" appears to contain a plain-text <type>

This is a security risk. Recommended secure alternatives:
1. Use an AAP Credential (Resources → Credentials → Add)
2. Use Ansible Vault encryption
3. Use a Survey with password-type field

Would you like to:
- "remove" - Remove the secret and proceed
- "credential" - Help set up an AAP Credential
- "override" - Proceed anyway (NOT RECOMMENDED)
```

**If no secrets detected**:
```
✓ Extra variables sanitization: PASSED
  No plain-text secrets detected in extra_vars.
```

### Step 6: Safety Summary

Compile the complete safety assessment:

```
Deployment Safety Assessment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Job Template: "<template_name>" (ID: <id>)
Target Inventory: "<inventory_name>" (Risk: <CRITICAL|HIGH|MEDIUM|LOW>)
Total Hosts: <count>
Privilege Escalation: <Yes|No>

Safety Checks:
✓ / ✗ Inventory risk classified
✓ / ✗ Extra variables sanitized
✓ / ✗ Scope assessed
✓ / ✗ Governance controls determined

Governance Controls:
- Check Mode: <MANDATORY|RECOMMENDED|OPTIONAL>
- Limit: <MANDATORY|RECOMMENDED|OPTIONAL> → Suggested: "<limit_value>"
- User Approval: <MANDATORY|OPTIONAL>

Recommendation: <Proceed with governance | Block until resolved | Proceed freely>

Next Step: <governance-launcher skill for governed execution>
```

## Critical: Human-in-the-Loop Requirements

This skill performs safety assessment before critical operations.

1. **If secrets detected**: BLOCK deployment and require user decision
2. **If CRITICAL risk**: Require explicit acknowledgment of governance requirements
3. **Never bypass governance**: Even if user insists, recommend check mode for production

## Dependencies

### Required MCP Servers
- `aap-mcp-job-management` - Job template retrieval
- `aap-mcp-inventory-management` - Inventory and host information

### Required MCP Tools
- `job_templates_list` (from aap-mcp-job-management) - Search job templates
  - Parameters: search (string), page_size (int)
- `job_templates_retrieve` (from aap-mcp-job-management) - Get template details
  - Parameters: id (int)
- `inventories_retrieve` (from aap-mcp-inventory-management) - Get inventory details
  - Parameters: id (int)
- `hosts_list` (from aap-mcp-inventory-management) - List hosts in inventory
  - Parameters: inventory (int), page_size (int)

### Related Skills
- `mcp-aap-validator` - **PREREQUISITE** - Validates AAP MCP before operations
- `governance-launcher` - **NEXT STEP** - Launches job with governance controls after safety check

### Reference Documentation
- [deployment-governance.md](../../docs/aap/deployment-governance.md) - Inventory risk classification and governance patterns
- [job-launching-best-practices.md](../../docs/aap/job-launching-best-practices.md) - Extra variables security and check mode patterns

## Example Usage

### Example 1: Production Deployment (High Risk)

**User Query**: "Deploy the new Web-App-v2 release to the Production inventory"

**Skill Response**:
```
I consulted deployment-governance.md to understand inventory risk classification.
I consulted job-launching-best-practices.md to understand extra variables security.

Deployment Safety Assessment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Job Template: "Web-App-v2-Deploy" (ID: 42)
Target Inventory: "Production-US" (Risk: CRITICAL)
Total Hosts: 45
Privilege Escalation: Yes

Safety Checks:
✓ Inventory risk classified: CRITICAL (matched "Production")
✓ Extra variables sanitized: No secrets detected
✓ Scope assessed: 45 hosts → phased rollout recommended

Governance Controls:
- Check Mode: MANDATORY
- Limit: MANDATORY → Suggested: "us-east[0:1]" (canary: first 2 hosts)
- User Approval: MANDATORY

⚠️ This is a CRITICAL-risk deployment. I recommend:
1. Running in Check Mode first on 2 canary hosts
2. Reviewing the dry-run results
3. Expanding to full us-east group
4. Then proceeding to us-west

Shall I proceed with the governed deployment workflow?
```

### Example 2: Development Deployment (Low Risk)

**User Query**: "Deploy the app to dev environment"

**Skill Response**:
```
Deployment Safety Assessment
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Job Template: "App-Deploy" (ID: 15)
Target Inventory: "Dev-Lab" (Risk: LOW)
Total Hosts: 3

Safety Checks:
✓ Inventory risk classified: LOW
✓ Extra variables sanitized: PASSED
✓ Scope assessed: 3 hosts

No additional governance required. Ready to launch.
```
