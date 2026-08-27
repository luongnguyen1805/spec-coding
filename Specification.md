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