---
name: figma-to-spec
description: Convert a Figma design URL into a structured feature spec following the spec-first layer model. Produces user stories, acceptance criteria, and implementation notes. Activate before frontend-design and design-taste-frontend when a Figma URL is the starting point for a build task.
---

# Figma to Spec

Load this skill when a Figma URL is the starting point for a design or build task.
Run it before any other design skills — the spec it produces feeds into `frontend-design`
and `design-taste-frontend`.

## Step 1 — Access the design

Two paths depending on available tools:

### Path A: Playwright MCP available

```
mcp__playwright__browser_navigate(url="<figma-url>")
mcp__playwright__browser_take_screenshot()
```

Navigate to the Figma URL and take a screenshot of each relevant frame or component.
If the URL requires Figma login, note this and fall back to Path B.

### Path B: No browser access

Ask the user to describe what they see. Prompt for:

```
1. What are the main screens or views in the design?
2. For each screen: what are the key elements (nav, content, actions, forms)?
3. What interactions are shown (hover states, modals, transitions)?
4. Are there any error states or empty states?
5. What are the primary user actions on each screen?
```

Collect answers before proceeding to Step 2.

## Step 2 — Extract design information

From the screenshots or user description, identify:

| Category | What to extract |
|----------|----------------|
| **Screens / views** | Names and purposes of each distinct view |
| **Components** | Reusable elements (cards, buttons, nav, forms) |
| **User flows** | How a user moves between screens |
| **States** | Default, loading, error, empty, success |
| **Data** | What data is displayed? What does the user input? |
| **Constraints** | Anything the design implies that's non-negotiable |

## Step 3 — Produce the spec

Output a structured spec document with these sections:

### Feature Summary

One paragraph: what this feature does, who it's for, and what problem it solves.

### User Stories

```
As a <user type>, I want to <action> so that <outcome>.
```

One story per distinct user goal. Aim for 3–6 stories total. If there are more,
group related ones or flag that the feature may need to be split.

### Screen Inventory

For each screen or view:

```
#### <Screen Name>
**Purpose:** <one sentence>
**Key elements:** <bulleted list of main UI elements>
**Primary action:** <the main thing a user does here>
**States:** default | loading | error | empty (note which are designed)
```

### Acceptance Criteria

Write in Gherkin for the most important behaviors:

```gherkin
Feature: <feature name>

  Scenario: <happy path>
    Given <starting state>
    When <user action>
    Then <expected outcome>

  Scenario: <error state>
    Given <starting state>
    When <user action that fails>
    Then <error handling expected>
```

Write at least one scenario per screen. Add error scenarios for any form or async operation.

### Implementation Notes

Flag anything from the design that has implementation implications:

- **Data dependencies**: what API endpoints or data models are needed
- **State management**: any complex state that will need careful handling
- **Animation/motion**: transitions between screens, micro-interactions
- **Accessibility**: any visible focus states, aria requirements implied by the design
- **Open questions**: anything ambiguous in the design that needs a decision before building

## Step 4 — Hand off to implementation

After producing the spec:

1. Save it to `docs/features/<feature-name>/spec.md` (or suggest the path)
2. Activate `kf:spec-first` if ADRs or EARS invariants are needed
3. Activate `frontend-design` + `design-taste-frontend` to begin the build

Confirm with the user: "Does this spec capture the design correctly? Any gaps before we start building?"

## Notes

- If the Figma URL requires authentication and Path A fails, always fall back to Path B — don't block on tool availability
- For complex designs with many screens, focus the spec on Phase 1 scope and note deferred screens explicitly
- The spec is a starting point, not a contract — expect it to evolve as implementation surfaces unknowns
