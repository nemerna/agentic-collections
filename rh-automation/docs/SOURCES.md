# Red Hat Documentation Sources

This document provides attribution for all official Red Hat documentation sources used in the Automation Agent knowledge base.

## Source Attribution Table

| Category | Document Title | Official Source URL | Sections Referenced | Last Verified |
|----------|---------------|---------------------|-------------------|---------------|
| **AAP Job Launching** | Controller User Guide - Launching Jobs | [docs.redhat.com](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/controller-job-templates#launching-job-templates) | Launching job templates, extra variables, limit, check mode | 2026-02-22 |
| **AAP Best Practices** | Ansible Automation Controller Best Practices | [docs.redhat.com](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/assembly-controller-best-practices) | Best practices for inventories, credentials, job templates | 2026-02-22 |
| **AAP Inventories** | Controller User Guide - Inventories | [docs.redhat.com](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/controller-inventories) | Inventory management, groups, host patterns | 2026-02-22 |
| **AAP Troubleshooting** | Troubleshooting Ansible Automation Platform - Jobs | [docs.redhat.com](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/troubleshooting_ansible_automation_platform/troubleshoot-jobs) | Common job failures, privilege escalation, module errors | 2026-02-22 |
| **AAP Troubleshooting** | Troubleshooting Ansible Automation Platform (2.4) | [docs.redhat.com](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.4/html-single/troubleshooting_ansible_automation_platform/index) | Platform troubleshooting, host connectivity | 2026-02-22 |
| **AAP Credentials** | Controller User Guide - Credentials | [docs.redhat.com](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6/html/using_automation_execution/controller-credentials) | Credential types, machine credentials, vault credentials | 2026-02-22 |
| **Ansible Errors** | Ansible Common Return Values | [docs.ansible.com](https://docs.ansible.com/ansible/latest/reference_appendices/common_return_values.html) | Return values, failure modes, error handling | 2026-02-22 |
| **RHEL Lifecycle** | Red Hat Enterprise Linux Life Cycle | [access.redhat.com](https://access.redhat.com/support/policy/updates/errata) | RHEL version support, EOL dates | 2026-02-22 |

## Documentation Categories

### Ansible Automation Platform
- **Primary Source**: Red Hat AAP Product Documentation (docs.redhat.com)
- **Focus**: Job launching governance, deployment best practices, troubleshooting
- **Versions Covered**: AAP 2.4, 2.5, 2.6
- **Update Frequency**: Per-release documentation updates

### Ansible Core
- **Primary Source**: Ansible Documentation (docs.ansible.com)
- **Focus**: Module error handling, return values, check mode behavior
- **Update Frequency**: Continuous community updates

### Red Hat Enterprise Linux
- **Primary Source**: Red Hat Customer Portal (access.redhat.com)
- **Focus**: RHEL lifecycle, version support, platform compatibility
- **Update Frequency**: Per-release updates

## Attribution Format

All documentation files include YAML frontmatter with source attribution:

```yaml
---
title: [Document Title]
category: aap|references
sources:
  - title: [Official Doc Title]
    url: [Official URL]
    sections: [Relevant sections]
    date_accessed: YYYY-MM-DD
tags: [keywords]
applies_to: [aap2.5, aap2.6]
last_updated: YYYY-MM-DD
---
```

## Verification

All sources listed above were verified as active and current as of February 22, 2026. The sources are:

1. **Official Red Hat Documentation** (docs.redhat.com) - Authoritative product documentation
2. **Red Hat Customer Portal** (access.redhat.com) - Knowledge base articles and lifecycle data
3. **Ansible Community Documentation** (docs.ansible.com) - Module and core references

## License and Usage

This knowledge base is derived from official Red Hat documentation licensed under Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0) or similar Red Hat documentation licenses. All credit for the original content belongs to Red Hat, Inc. and its contributors.

**Important**: This knowledge base is a derivative work for educational and operational purposes. For the most up-to-date and authoritative information, always consult the official Red Hat documentation at the URLs listed above.
