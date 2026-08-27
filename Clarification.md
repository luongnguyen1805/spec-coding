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