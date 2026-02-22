---
title: Red Hat Automation Agent - Documentation Index
category: meta
sources:
  - title: Red Hat Product Documentation
    url: https://docs.redhat.com
    sections: Ansible Automation Platform, RHEL, AAP Troubleshooting
    date_accessed: 2026-02-22
last_updated: 2026-02-22
---

# Red Hat Automation Agent - Documentation Index

This knowledge base provides comprehensive Red Hat-specific patterns for governed deployment and forensic troubleshooting on Ansible Automation Platform.

## Quick Navigation

### Priority P0 (Core Documentation)
- **[Job Launching Best Practices](aap/job-launching-best-practices.md)** - HIGHEST VALUE
  - Check mode (dry run) patterns and when to use
  - Limit (host scope control) strategies
  - Extra variables security and secret scanning
  - Post-execution noise reduction (changed-only summaries)

- **[Deployment Governance Patterns](aap/deployment-governance.md)**
  - Inventory risk classification (production/staging/development)
  - Phased rollout strategies (canary, geographic, environment ladder)
  - Approval workflows and human-in-the-loop patterns

- **[AAP Job Troubleshooting Guide](aap/troubleshooting-jobs.md)**
  - Common failure patterns (6 categories with resolution steps)
  - Event analysis and failure sequence reconstruction
  - Host fact correlation for root cause analysis
  - Resolution decision tree

- **[Error Classification Taxonomy](references/error-classification.md)**
  - Platform vs Code error classification
  - Severity scoring and priority matrix
  - Fact-based root cause detection
  - Resolution templates

## Documentation Structure

```
docs/
├── INDEX.md (this file)
├── SOURCES.md (official Red Hat source attribution)
├── aap/                           # AAP-specific patterns
│   ├── README.md
│   ├── job-launching-best-practices.md (P0)
│   ├── deployment-governance.md (P0)
│   └── troubleshooting-jobs.md (P0)
├── references/                    # Reference documentation
│   ├── README.md
│   └── error-classification.md (P0)
└── .ai-index/                     # AI inference optimization
    ├── semantic-index.json
    ├── task-to-docs-mapping.json
    └── cross-reference-graph.json
```

## How to Use This Documentation (For AI Agents)

### 1. Intelligent Document Discovery

**Always start by reading the semantic index**:
```
Read: docs/.ai-index/semantic-index.json (~200 tokens)
```

The semantic index enables:
- **Query-based discovery**: Match semantic keywords to your task
- **Task mapping shortcuts**: Pre-computed doc sets for governance and troubleshooting workflows
- **Error type inference**: Automatic doc selection based on error characteristics

### 2. Task-Based Document Loading

**Example Workflow - Governance Deployment**:
```
1. Read semantic-index.json
2. Detect: Task = "governance deployment" targeting production
3. Load from task_mappings["governance_deployment"]:
   - aap/job-launching-best-practices.md (check mode, limit, extra_vars)
   - aap/deployment-governance.md (risk classification, approval workflow)
4. Execute governance workflow using loaded patterns
```

**Example Workflow - Job Failure Forensics**:
```
1. Read semantic-index.json
2. Detect: Task = "forensic troubleshooting" for failed job
3. Load from task_mappings["forensic_troubleshooting"]:
   - aap/troubleshooting-jobs.md (failure patterns, event analysis)
   - references/error-classification.md (platform vs code classification)
4. Perform forensic analysis using loaded patterns
```

### 3. Progressive Disclosure Pattern

**Load docs incrementally as needed**:
- **Phase 1 (Pre-flight)**: Load deployment-governance.md for risk classification
- **Phase 2 (Execution)**: Load job-launching-best-practices.md for launch parameters
- **Phase 3 (Troubleshooting)**: Load troubleshooting-jobs.md if job fails
- **Phase 4 (Resolution)**: Load error-classification.md for root cause analysis

### 4. Cross-Reference Navigation

Use the cross-reference graph to find related documentation:
```
If reading: aap/troubleshooting-jobs.md
Also consider:
  - references/error-classification.md (complements: error taxonomy)
  - aap/job-launching-best-practices.md (prerequisite: governance prevents many failures)
```

## Common Workflows

### Workflow 1: Governance-First Production Deployment (Use Case 1)

**Task**: "Deploy the new Web App version to Production"

**Required Docs**:
1. `aap/deployment-governance.md` (risk classification, approval workflow)
2. `aap/job-launching-best-practices.md` (check mode, limit, extra_vars)

### Workflow 2: Forensic Job Failure Analysis (Use Case 2)

**Task**: "Job #502 failed halfway through"

**Required Docs**:
1. `aap/troubleshooting-jobs.md` (event analysis, failure patterns)
2. `references/error-classification.md` (platform vs code classification)

### Workflow 3: Post-Deployment Issue Investigation

**Task**: "The deployment succeeded but the service isn't working"

**Required Docs**:
1. `aap/troubleshooting-jobs.md` (event analysis, host fact correlation)
2. `aap/job-launching-best-practices.md` (post-execution analysis)
3. `references/error-classification.md` (error classification)

## Documentation Quality Standards

All documents follow these standards:

### YAML Frontmatter (Required)
```yaml
---
title: [Document Title]
category: aap|references
sources:
  - title: [Official Red Hat Doc Title]
    url: [Official URL]
    sections: [Relevant sections]
    date_accessed: YYYY-MM-DD
tags: [keyword1, keyword2, keyword3]
applies_to: [aap2.5, aap2.6]
semantic_keywords: [keyword phrases for AI discovery]
use_cases: [use_case_ids for task mapping]
related_docs: [cross-references]
last_updated: YYYY-MM-DD
---
```

### Content Structure (Required)
- **Lead with actionable patterns**: Show decision trees and checklists first
- **Production-ready examples**: Real-world patterns, not toy examples
- **Error handling included**: Every pattern includes what to do when things fail
- **Red Hat sourced**: All content derived from official Red Hat documentation

## Official Source Attribution

**All documentation in this knowledge base is derived from official Red Hat sources**.

See [SOURCES.md](SOURCES.md) for complete source attribution table.

## AI Inference Optimization

### Semantic Index (`semantic-index.json`)
- Document metadata with semantic keywords
- Use case mappings for task-based discovery
- Error type inference hints

### Task-to-Docs Mapping (`task-to-docs-mapping.json`)
- Pre-computed doc sets for governance and troubleshooting workflows
- Required vs optional doc indicators
- Estimated token usage per workflow

### Cross-Reference Graph (`cross-reference-graph.json`)
- Document relationship graph
- Complement and prerequisite relationships
- Confidence scores

## Quick Reference Tables

### AAP Version Support
| AAP Version | Status | MCP Support |
|-------------|--------|-------------|
| AAP 2.4 | Supported | Partial |
| AAP 2.5 | Supported | Full |
| AAP 2.6 | Current | Full |

### Error Category Quick Reference
| Error Signal | Category | Resolution Owner |
|-------------|----------|-----------------|
| Host unreachable | Platform | Infrastructure |
| Module not found | Code | Developer |
| Privilege escalation | Platform | AAP Admin |
| Service failed | Mixed | Investigate |
| Package conflict | Mixed | Investigate |
| Syntax error | Code | Developer |
