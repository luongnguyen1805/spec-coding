
# Role & Persona

You are a senior Software Developer.

# In-place Knowledge and Memory

This repository maintain in-place metadata layer to help agents efficiently discover relevant information, understand the repository, and preserve long-term knowledge across work sessions.

The metadata layer exists alongside the primary repository content but remains completely independent of it. Primary content (source code, documentation, specifications, reports, manuals, templates, presentations, etc.) should never reference or depend upon the metadata layer.

## Metadata Model

Each directory may contain the following metadata folders:

```text
.navigation/
    Index.md
    {name}.md

.knowledge/
    Index.md
    {topic}.md

.memory/
    Index.md
    {topic}.md
```

Each metadata folder has a distinct responsibility.

### `.navigation`

Repository navigation.

This folder helps agents quickly locate relevant files and folders without broadly exploring the repository.

`Index.md` serves as the entry point for the current directory. It should provide a concise overview of the directory and reference the available navigation documents.

Each `{name}.md` describes a single file or folder, including its:

- purpose
- responsibilities
- major contents
- relationships with nearby files or folders

`.navigation` answers:

> Where should I look?

### `.knowledge`

Stable repository knowledge.

This folder stores long-term information describing how the repository is designed and expected to work.

`Index.md` provides a summary of the available knowledge topics.

Each `{topic}.md` should focus on a single long-term topic, such as:

- architecture
- design rationale
- conventions
- interfaces
- constraints
- domain concepts
- terminology

`.knowledge` answers:

> How does this work?

### `.memory`

Operational experience.

This folder preserves knowledge gained while working on the repository that is expected to benefit future work.

`Index.md` summarizes available memory topics.

Each `{topic}.md` records a single long-term operational topic, such as:

- debugging discoveries
- implementation pitfalls
- migration notes
- recurring issues
- lessons learned
- operational observations

Do **not** store temporary task status, implementation plans, or short-lived information.

`.memory` answers:

> What have previous agents learned?

## Primary Content vs Metadata

The metadata layer supplements the repository but never replaces it.

The primary repository content is always the authoritative source.

When metadata conflicts with primary content:

- trust the primary content;
- update the metadata if appropriate;
- never modify primary content solely to match outdated metadata.

## Metadata Discovery

Before exploring a significant portion of the repository:

1. Locate the nearest metadata layer.
2. Read `.navigation/Index.md`.
3. Open only the navigation documents relevant to the current task.
4. Read `.knowledge` only when additional domain understanding is required.
5. Read `.memory` only when previous experience may influence the current task.
6. Explore the primary repository only after reviewing the relevant metadata.

Expand exploration only when additional context is required.

Avoid scanning unrelated areas of the repository.

If no metadata layer exists in the current directory, continue searching parent directories until one is found. Do not search unrelated branches unless required by the current task.

## Metadata Ownership

Metadata should remain local to the area it describes.

Each metadata layer is responsible only for:

- its current directory;
- files directly within that directory;
- information shared among those files.

Child directories should maintain their own metadata.

Parent directories should summarize child areas rather than duplicate their detailed metadata.

Always store metadata as close as possible to the work it describes.

## Maintaining Metadata

When recording long-term information:

1. Locate the nearest metadata layer.
2. Update existing metadata whenever appropriate.
3. Create a new metadata document only when introducing a genuinely distinct long-term topic.
4. Update the corresponding `Index.md` whenever metadata documents are added, removed, renamed, or reorganized.

Create metadata only when it is expected to improve future work across multiple work sessions.

Do not:

- create metadata for temporary tasks;
- duplicate the same information across multiple metadata documents;
- accumulate unrelated information into a single document;
- modify primary repository content solely to reference the metadata layer.

## Keep Metadata Focused

Avoid creating "god files."

Instead:

- keep each metadata document focused on a single topic;
- prefer many small, localized documents over large centralized ones;
- split documents when they become difficult to navigate;
- keep every `Index.md` concise and focused on discovery rather than detailed documentation.

Agents should only need to read metadata relevant to the current task rather than the entire repository.

## Guiding Principles

The metadata layer should always be:

- local;
- lightweight;
- discoverable;
- incremental;
- stable;
- easy to maintain.

The objective is to minimize unnecessary repository exploration while enabling agents to quickly locate relevant information, understand the repository, and leverage accumulated knowledge and operational experience.

# Specification

## 1. Purpose

`Source/Specs/` is the authoritative source of truth for the source specification.

All generated output MUST conform to the specifications defined under `Source/Specs/`.

## 2. Specification Authority

* `Source/Specs/` has the **highest priority** among project artifacts.
* `Source/Specs/` defines the intended behavior, structure, constraints, and requirements of the project.
* When generated content conflicts with `Specs/`, the specification takes precedence.
* Generated content MUST NOT redefine, override, or silently contradict the specification.

## 3. Generation Rule

Before generating or modifying any output in `Source/`:

1. Read and understand the applicable specification in `Source/Specs/`.
2. Treat the specification as the authoritative model.
3. Generate the output according to that model.
4. Verify that the generated output does not contradict or violate the specification.

All generated output MUST follow the model defined by `Source/Specs/`.

## 4. Conflict Resolution

When information conflicts across transient artifacts, resolve conflicts according to this priority:

* A  transient artifact MUST be corrected or regenerated when it conflicts with the specification.

* The existence of a previously generated artifact does not establish authority over the specification.

## 5. Specification Integrity

Do not modify `Source/Specs/` merely to make generated output appear valid.

If the specification itself must change, that change MUST be intentional and explicitly treated as a specification change. After the specification changes, affected transient artifacts should be regenerated or updated to conform to the new specification.

# Clarification

## Purpose

`Source/Specs` defines **how the goal-source should be**. It describes the intended result, structure, behavior, and constraints of the system.

`Source/Clars` defines **development steps in detail** to achieve parts of the specification. A clarification translates a portion of the specification into concrete implementation guidance without becoming the specification itself.

## Organization

```text
Source/
	Specs/
		...

	Clars/
		Index.md
		1-Code organization
		1-Code organization/

		2-UI code organization
```

Each clarification consists of:

* A clarification file defining the development guidance.
* Optionally, a folder containing additional detailed clarifications.

The clarification name starts with an **order index**:

```text
<Order>-<Clarification-name>
```

For example:

```text
1-Code organization
2-UI code organization
3-Network layer
```

## Clarification Order

The order index defines the development sequence and establishes a dependency between clarifications.

A clarification with order `N` may rely on clarifications with a lower order that have already been completed.

For example:

```text
1-Code organization
2-UI code organization
3-Network layer
```

`2-UI code organization` may assume the requirements and development decisions established by `1-Code organization`.

Therefore:

* Lower-order clarifications are expected to be completed before higher-order clarifications.
* A clarification must not assume the implementation of a higher-order clarification.
* Higher-order clarifications may build upon lower-order clarifications.
* The order represents **development dependency**, not specification priority.

## Relationship Between Specification and Clarification

The relationship is:

```text
Source/Specs
    ↓ defines the desired result
Source/Clars
    ↓ defines how to develop toward that result
Implementation
```

1. Specification has higher authority than Clarification.

2. Clarification must not introduce requirements that are absent from the Specification.

3. Clarification may specify implementation details, sequencing, constraints, examples, and development procedures.

4. If a Clarification conflicts with the Specification, update the Clarification rather than modifying the implementation to satisfy the conflict. Clarifications must remain consistent with the specifications.

`Source/Clars` is therefore an implementation-oriented layer, while `Source/Specs` remains the authoritative definition of the desired system.
