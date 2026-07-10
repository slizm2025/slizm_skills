---
name: tech-doc-implementation
description: Implement, refactor, extend, or modify project code from a technical document, design document, requirements specification, API specification, architecture document, product document, or implementation plan. Use when the user asks Codex to perform the documented code changes, not when they only want a document drafted or reviewed. Reconcile the document with the current project, trace every normative requirement to code and validation, make the smallest compatible change set, and ask only when an unresolved choice would materially change behavior, contracts, data, security, or delivery risk.
---

# Implement code from a technical document

Treat the document as the target and the current project as the implementation constraint. Preserve unrelated user changes and existing behavior outside the documented scope.

## Required outcome

Complete the task only when:

- every normative document requirement is implemented, explicitly out of scope, or blocked with a stated reason;
- every changed file and behavior maps to at least one document requirement;
- relevant validation has run, or its absence and resulting confidence limit are reported;
- no unresolved material ambiguity is hidden behind an implementation choice.

## Decision rule

Resolve ordinary implementation choices from established project conventions. Ask the user only when the remaining alternatives would materially change one or more of:

- observable product behavior or acceptance results;
- public APIs, persisted data, permissions, authentication, billing, or security posture;
- dependency policy, migration strategy, cross-module ownership, or backward compatibility;
- the documented scope or a requirement's meaning.

When asking, state the conflicting evidence, affected requirements, available choices, and practical consequence of each choice. Group related blockers into one focused question.

## Workflow

### 1. Establish the implementation baseline

Read every document and explicit user supplement that defines the requested change. Record internally:

- source path or conversation source and available version identifier;
- requested project or module scope;
- available branch, commit, tag, or analysis timestamp;
- each normative requirement as `REQ-001`, `REQ-002`, and so on;
- explicit exclusions, invariants, acceptance criteria, conflicts, and unknowns.

Distinguish document requirements from examples, commentary, current-state descriptions, and inferred engineering preferences.

This step is complete when every normative statement is represented by a requirement ID or recorded as an unresolved blocker.

### 2. Verify project fit and inspect the implementation

Confirm that the requested workspace is the project described by the document using decisive evidence or multiple independent strong signals. Then inspect only the code needed to establish:

- active entry points and current observable behavior;
- owning modules, symbols, schemas, configuration, generated sources, and dependencies;
- existing architecture, naming, validation, error handling, logging, and test conventions;
- user-owned or unrelated worktree changes that must remain untouched.

Treat runtime code, declarative configuration, schemas, generators, infrastructure definitions, and tests as possible authoritative implementation sources. Treat README files, comments, examples, and historical documents as supporting evidence.

Stop when project identity cannot be established or required implementation sources are missing. Explain what was found, what is missing, and which requirements cannot be implemented safely.

This step is complete when every requirement has enough current-project evidence to choose an implementation location or has a precise blocker.

### 3. Build the implementation trace

Split the work into reviewable implementation units. Maintain an internal trace:

| Unit | Requirements | Current evidence | Planned files/symbols | Validation | Status |
|---|---|---|---|---|---|

Each unit must have:

- one coherent behavior or contract change;
- at least one requirement ID;
- evidence for the chosen project location;
- a validation method proportional to its risk.

Keep units scoped to required behavior and follow existing project seams.

This step is complete when every requirement is covered by at least one unit and every unit is justified by a requirement.

### 4. Gate and implement each unit

Before editing a unit, verify internally:

- the requirement is unambiguous enough to implement;
- the proposed location and dependency direction match the project;
- the change preserves out-of-scope behavior;
- any public contract, data, security, migration, or dependency impact is authorized;
- the planned validation can detect the intended behavior.

Proceed autonomously when project conventions resolve non-material choices. Pause under the decision rule when they do not.

During implementation:

- modify only files required by traced units;
- reuse established types, utilities, services, components, and conventions;
- keep current-state and target-state assumptions visible in code and tests;
- update tests and generated or declarative sources at their authoritative layer;
- preserve unrelated user changes and avoid broad mechanical rewrites.

A unit is complete only when its code change and validation coverage match all mapped requirements.

### 5. Validate from narrow to broad

Run the strongest relevant checks available, starting with the smallest signal that exercises the change:

1. targeted tests or focused reproduction;
2. affected type checking, linting, schema, or static validation;
3. broader tests or build when proportionate to the change and practical.

If a check fails, determine whether the failure comes from the implementation, the documented requirement, the environment, or a pre-existing condition. Fix in-scope implementation failures. Report environmental and pre-existing failures with evidence rather than masking them.

Validation is complete when every implementation unit has a result or an explicit unvalidated boundary.

### 6. Perform the final trace audit

Before reporting completion, confirm:

- every `REQ-nnn` is implemented, excluded by the source, or explicitly blocked;
- every modified file belongs to a traced unit;
- tests and validation assertions reflect the document rather than invented requirements;
- no project, document, or code baseline changed in a way that invalidates the analysis;
- the working tree contains no accidental files or unrelated modifications created by the task.

If the document or relevant code changed during implementation, refresh the affected trace and validation before completion.

## Final report

Report concisely:

```text
Implementation result:
- Document baseline:
- Code baseline:
- Requirements implemented:
- Requirements blocked or excluded:
- Modified files:
- Validation performed and results:
- Unvalidated boundaries or known limitations:
```

Claim only behavior demonstrated by the resulting code and available validation.
