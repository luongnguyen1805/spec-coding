---

name: point-explore
description: Use when the user says "explore for {topic}", "explore {topic}", or "explore point {Section}/XXX" (optionally in a given file). Expands a topic or an existing point into a compact, structured knowledge map — discovering related points, aspects, dimensions, and subtopics — instead of writing prose explanations.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Point Exploration

* Treat each keyword, phrase, or sentence as an **exploration point**.
* When asked to explore a point, expand it by discovering important related points, aspects, dimensions, and subtopics.
* Preserve existing points and hierarchy; use them as anchors for further exploration.
* Add missing points when necessary to sufficiently cover the explored point.
* Explore important sub-points recursively.
* Prefer ordered or unordered points over prose.
* Keep the exploration concise and focused on meaningful points.
* Prefer no more than **3 levels of indentation** below the explored point.

## Triggers

* `explore for {topic}` or `explore {topic}` (no file given):

  * Start a fresh exploration of `{topic}` as the root point.
  * Produce a new structured knowledge map from scratch, following all rules below.
  * Output directly in the response unless the user asks for a file.
* `File ABC.md, explore point {Section}/XXX`:

  * Locate `{Section}/XXX` in `ABC.md` and expand that point in place.
  * Add discovered points as indented ordered or unordered points beneath the explored point.
  * Preserve the existing content and hierarchy unless modification is explicitly requested.
  * Do not replace an existing point with a prose explanation.
  * Do not assume the existing points are exhaustive; discover and add important missing points.
  * Explore the point sufficiently to cover its important dimensions, but stop when further decomposition produces mostly details rather than meaningful points.

## Specs / Clars Independence

* When the target file lives under `Source/Specs` or `Source/Clars` (e.g. `Specs.md`, `UI.md`), points describe the concepts/keywords that `Source` (the implementation) must follow — the spec is prescriptive, not a description of the current `Source` implementation.
* Specs/Clars must not depend on `Source`.

  * Do not add file paths, line numbers, or other pointers into `Source` (e.g. `Source/App/...`) as references or evidence for a point.
  * Class/type/constant names may still appear as points (they are shared vocabulary between spec and code), but never as a link into where they live in `Source`.
  * If evidence from the current implementation is genuinely needed to inform the exploration, use it to decide what the point should say — do not carry the path/evidence itself into the file.

## Point Format

* A point may be a **keyword, phrase, or concise sentence**.
* Every point must be **concise**: express the concept using the fewest words necessary to preserve its meaning and precision.
* Prefer keywords or short phrases when they fully represent the concept.
* Use a sentence only when a phrase would lose an important relationship, condition, observation, or conclusion.
* A sentence may be longer when necessary for precision, but remove unnecessary qualifiers, repetition, background, rationale, and explanatory wording.
* A point must represent a **single distinct concept, aspect, component, relationship, observation, or conclusion**.
* Do not combine multiple independently meaningful ideas into one point merely to keep the hierarchy shallow.
* Do not split a single meaningful concept merely because its concise expression requires a longer sentence.
* Prefer one idea per point; create separate sub-points when a point contains multiple independently meaningful ideas.
* Do not use paragraphs, collections of explanations, or narrative descriptions as points.
* Do not turn details, examples, rationale, implementation notes, or explanations into additional points unless they represent a distinct concept.
* Use references for extensive explanations, examples, implementation details, evidence, or other information that does not belong naturally as a point.

### Conciseness Test

* Before adding a point, ask: **Can this be expressed more briefly without losing meaning?**
* Remove words that only explain, justify, introduce, or repeat the point.
* Prefer:

  * `Connection retry policy`
  * `Retry after disconnection`
  * `Scan results may be cached`
* Avoid:

  * `The connection retry policy that should be used when the device becomes disconnected`
  * `The system should retry the connection after the device has become disconnected`
  * `The scan results may sometimes be cached by the system`
* Do not add explanatory prose to make a point sound complete when the concept is already clear from its position in the hierarchy.

## Exploration Depth

* Prefer a maximum of **3 levels of indentation** from the explored point.
* Use deeper levels only when necessary to represent an important structural relationship.
* Do not create deep hierarchies merely to capture implementation details.

## Point vs. Detail

* **Point:** a concise, distinct concept that can be independently identified and, when useful, explored further.
* **Detail:** information that explains, justifies, implements, illustrates, or provides evidence for a point.
* Keep points in the hierarchy.
* Keep extensive details in references.
* The distinction is based on **semantic unity**, not sentence length.
* Conciseness does not mean removing essential meaning merely to shorten a point.

## Example

```text
UI
    Windows
        Top Most
        Main Window
    Views
        Layout
        State
        Lifecycle
```

A concise sentence can still be a valid point:

```text
- A window can remain above other windows when its level is configured appropriately.
```

Prefer a shorter expression when the meaning is preserved:

```text
- Window level controls whether it stays above other windows.
```

Not:

```text
UI
    Windows
        Windows are responsible for managing the application's visual presentation and interaction with the user.
        This is useful because windows provide the primary container for displaying content.
        In some situations, developers may need to configure windows differently depending on the application's requirements.
```

The latter is explanatory detail rather than a structured point and should be moved to a reference.

## Result

* The result should be a **compact structured knowledge map**, not a detailed explanation.
* Every point should be concise enough to understand at a glance.
* The hierarchy should answer **"What belongs here?"** rather than **"What do I know about this?"**
* Use references when the user needs the details behind a point.
* Prefer **semantic completeness with minimum wording** over verbose completeness.
