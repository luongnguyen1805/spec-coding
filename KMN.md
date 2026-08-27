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