---
name: mcp-aap-validator
description: |
  This skill should be used when the user asks to "validate AAP MCP", "check if AAP is configured", "verify aap-mcp servers", "test AAP connection", or when other skills need to verify AAP MCP server availability before executing job management or inventory operations.
model: haiku
color: yellow
---

# MCP AAP Validator

Validates that AAP (Ansible Automation Platform) MCP servers are properly configured and accessible for job management and inventory operations.

## When to Use This Skill

Use this skill when:
- Validating AAP MCP server configuration before governance deployments
- Troubleshooting connection issues with AAP MCP servers
- Verifying environment setup for AAP workflows
- Other skills need to confirm AAP MCP server availability as a prerequisite (e.g., `deployment-safety-checker`, `job-failure-analyzer`)

Do NOT use when:
- Performing safety checks on deployments → Use `deployment-safety-checker` skill
- Launching governed jobs → Use `governance-launcher` skill
- Analyzing failed jobs → Use `job-failure-analyzer` skill

## Workflow

### Step 1: Check MCP Server Configuration

**Action**: Verify that AAP MCP servers exist in [.mcp.json](../../.mcp.json)

**Required AAP MCP Servers**:
- `aap-mcp-job-management` - Job template and execution management
- `aap-mcp-inventory-management` - Inventory, host, and fact management

**How to verify**:
1. Read the `.mcp.json` file in the rh-automation directory
2. Check if `mcpServers` object contains both required servers:
   - `aap-mcp-job-management` key
   - `aap-mcp-inventory-management` key
3. Verify each server configuration has:
   - `type: "http"` or `url` field
   - `headers` with Authorization Bearer token
   - `env` with required variables

**Expected result**: Both AAP MCP servers configured with proper HTTP structure

**Report to user**:
- ✓ "MCP server `aap-mcp-job-management` is configured in .mcp.json"
- ✓ "MCP server `aap-mcp-inventory-management` is configured in .mcp.json"
- ✗ "MCP server `aap-mcp-job-management` not found in .mcp.json"
- ✗ "MCP server `aap-mcp-inventory-management` not found in .mcp.json"

**If either AAP server missing**: Proceed to Human Notification Protocol (Step 4)

### Step 2: Verify Environment Variables

**Action**: Check that required environment variables are set (without exposing values)

**Required Environment Variables**:
- `AAP_SERVER` - Base URL for AAP instance
- `AAP_API_TOKEN` - Authentication token for AAP API

**CRITICAL SECURITY CONSTRAINT**:
- **NEVER print environment variable values** in user-visible output
- Only report presence/absence
- Do NOT use `echo $VAR_NAME` or display actual values

**How to verify** (without exposing values):
```bash
if [ -n "$AAP_SERVER" ]; then
  echo "✓ AAP_SERVER is set"
else
  echo "✗ AAP_SERVER is not set"
fi

if [ -n "$AAP_API_TOKEN" ]; then
  echo "✓ AAP_API_TOKEN is set"
else
  echo "✗ AAP_API_TOKEN is not set"
fi
```

**Report to user**:
- ✓ "Environment variable AAP_SERVER is set"
- ✓ "Environment variable AAP_API_TOKEN is set"
- ✗ "Environment variable AAP_SERVER is not set"
- ✗ "Environment variable AAP_API_TOKEN is not set"

**If missing**: Proceed to Human Notification Protocol (Step 4)

### Step 3: Test MCP Server Connection

**Action**: Attempt connectivity test to verify server accessibility

**Test approach**:
1. **Test Job Management Server**:
   - Tool: `job_templates_list` (from aap-mcp-job-management)
   - Parameters: `page_size: 1` (minimal query)
   - Expected: Returns list (even if empty)
   - Success: Server responds with valid data
   - Failure: Connection timeout, auth error, or server unavailable

2. **Test Inventory Management Server**:
   - Tool: `inventories_list` (from aap-mcp-inventory-management)
   - Parameters: `page_size: 1` (minimal query)
   - Expected: Returns list (even if empty)
   - Success: Server responds with valid data
   - Failure: Connection timeout, auth error, or server unavailable

**Report to user**:
- ✓ "Successfully connected to aap-mcp-job-management"
- ✓ "Successfully connected to aap-mcp-inventory-management"
- ⚠ "Configuration appears correct but connectivity test unavailable"
- ✗ "Cannot connect to aap-mcp-job-management (check server status and credentials)"
- ✗ "Cannot connect to aap-mcp-inventory-management (check server status and credentials)"

**Common connection errors**:
- `401 Unauthorized`: Invalid or expired AAP_API_TOKEN
- `403 Forbidden`: Token lacks required permissions
- `404 Not Found`: Incorrect AAP_SERVER URL or missing MCP endpoints
- `Connection timeout`: Server unreachable or network issue
- `SSL/TLS error`: Certificate verification issues

**If connection fails**: Proceed to Human Notification Protocol (Step 4)

### Step 4: Human Notification Protocol

When validation fails, follow this protocol:

**1. Stop Execution Immediately** - Do not attempt MCP tool calls

**2. Report Clear Error**:

For missing MCP server configuration:
```
❌ Cannot validate AAP MCP servers: Servers not configured in .mcp.json

📋 Setup Instructions:
1. Add AAP MCP server configurations to rh-automation/.mcp.json
2. Set environment variables:
   export AAP_SERVER="https://your-aap-server.com"
   export AAP_API_TOKEN="your-api-token"
3. Restart to reload MCP servers

🔗 Documentation: See rh-automation/README.md for setup
```

For missing environment variables:
```
❌ Cannot validate AAP MCP: Required environment variables not set

📋 Setup Instructions:
1. Set required environment variables:
   export AAP_SERVER="https://your-aap-server.com"
   export AAP_API_TOKEN="your-api-token"

2. To get an API token:
   - Log in to AAP Web UI
   - Navigate to Users → [Your User] → Tokens
   - Create a new Personal Access Token

⚠️ SECURITY: Never commit tokens to source control

3. Restart to reload environment variables
```

For connection failures:
```
❌ Cannot connect to AAP MCP servers

📋 Troubleshooting steps:
1. Verify AAP server is accessible: curl -I ${AAP_SERVER}
2. Verify API token is valid (check AAP Web UI → Users → Tokens)
3. Test authentication:
   curl -H "Authorization: Bearer ${AAP_API_TOKEN}" ${AAP_SERVER}/api/controller/v2/ping/
4. Verify AAP MCP endpoints are enabled
5. Check firewall and network connectivity
```

**3. Request User Decision**:
```
❓ How would you like to proceed?

Options:
- "setup" - Help me configure the AAP MCP servers now
- "skip" - Skip validation and try the operation anyway (not recommended)
- "abort" - Stop the workflow entirely

Please respond with your choice.
```

**4. Wait for Explicit User Input** - Do not proceed automatically

### Step 5: Validation Summary

**Success case**:
```
✓ AAP MCP Validation: PASSED

Configuration:
✓ MCP server aap-mcp-job-management configured
✓ MCP server aap-mcp-inventory-management configured
✓ Environment variable AAP_SERVER is set
✓ Environment variable AAP_API_TOKEN is set
✓ Job management server connectivity verified
✓ Inventory management server connectivity verified

Ready to execute AAP operations.
```

**Partial success case**:
```
⚠ AAP MCP Validation: PARTIAL

Configuration:
✓ MCP servers configured in .mcp.json
✓ Environment variables are set
⚠ Server connectivity could not be fully tested

Note: Configuration appears correct. Connection will be verified on first tool use.
```

**Failure case**:
```
✗ AAP MCP Validation: FAILED

Issues found:
✗ [Specific issue 1]
✗ [Specific issue 2]

See troubleshooting steps above.
```

## Dependencies

### Required Files
- [.mcp.json](../../.mcp.json) - MCP server configuration file

### Required MCP Servers
- `aap-mcp-job-management` - AAP job template and execution management
- `aap-mcp-inventory-management` - AAP inventory and host management

### Required MCP Tools
- `job_templates_list` (from aap-mcp-job-management) - List job templates (for connectivity test)
- `inventories_list` (from aap-mcp-inventory-management) - List inventories (for connectivity test)

### Required Environment Variables
- `AAP_SERVER` - Base URL for AAP instance
- `AAP_API_TOKEN` - Personal Access Token for AAP API

### Related Skills
- `deployment-safety-checker` - Invokes this validator before safety analysis
- `governance-launcher` - Invokes this validator before job launch
- `job-failure-analyzer` - Invokes this validator before event analysis
- `host-fact-inspector` - Invokes this validator before fact retrieval

## Validation Freshness Policy

**Session-based validation**: Once validation succeeds in a session, subsequent skills can skip re-validation unless:
1. User explicitly requests re-validation
2. Previous MCP tool call failed with connection error
3. Configuration changes were made to .mcp.json
4. Environment variables were modified

**How other skills use this**:
```
IF validation_passed_in_session AND no_config_changes:
  Skip validation, proceed with operation
ELSE:
  Invoke mcp-aap-validator skill
  IF validation PASSED:
    Mark validation_passed_in_session = true
    Proceed with operation
  ELSE:
    Report error, ask user for decision
```
