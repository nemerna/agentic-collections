---
name: execution-summary
description: |
  Generate concise execution reports for audit and learning purposes.

  Use this skill when:
  - "Generate execution summary"
  - "Create execution report"
  - "Summarize what was used"
  - "Show workflow audit trail"
  - After completing a governance deployment or troubleshooting session
model: haiku
color: green
---

# Execution Summary Skill

Generates concise execution reports summarizing the agents, skills, tools, and documents used during a workflow session. Provides audit trails for governance compliance and operational learning.

## When to Use This Skill

Use this skill when:
- After completing a governance deployment workflow
- After completing a forensic troubleshooting session
- When generating audit reports for compliance
- When documenting workflow execution for team learning

Do NOT use when:
- Performing active deployment or troubleshooting (use appropriate agent instead)

## Workflow

### Step 1: Analyze Conversation History

Review the current conversation to extract:
- Agents invoked and their outcomes
- Skills invoked and their outcomes
- MCP tools called and their results
- Documents consulted
- User decisions at confirmation points
- Errors encountered and how they were resolved

### Step 2: Generate Report

**Output Format**:

```markdown
# Execution Summary Report
**Generated**: <timestamp>
**Workflow**: <Governance Deployment | Forensic Troubleshooting | Mixed>

## Agents Used
| Agent | Purpose | Outcome |
|-------|---------|---------|
| <agent_name> | <what it did> | <SUCCESS/PARTIAL/FAILED> |

## Skills Invoked
| Skill | Step | Purpose | Outcome |
|-------|------|---------|---------|
| mcp-aap-validator | Prerequisite | AAP MCP validation | PASSED |
| <skill_name> | <step_N> | <purpose> | <outcome> |

## MCP Tools Called
| Tool | Server | Parameters | Result |
|------|--------|-----------|--------|
| <tool_name> | <server> | <key params> | <summary> |

## Documents Consulted
| Document | Purpose |
|----------|---------|
| <doc_path> | <why it was read> |

## Human Decisions
| Decision Point | User Choice | Impact |
|----------------|-------------|--------|
| <what was asked> | <user's answer> | <what happened> |

## Key Findings
1. <finding_1>
2. <finding_2>

## Outcome
<Final result summary>

## Recommendations
1. <recommendation_1>
2. <recommendation_2>
```

## Dependencies

### Related Skills
- All other rh-automation skills (this skill reports on their execution)

### Reference Documentation
- No specific docs required (uses conversation history analysis)
