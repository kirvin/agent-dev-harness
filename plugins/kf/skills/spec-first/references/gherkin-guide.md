# Gherkin Feature File Conventions

Feature files are executable acceptance criteria. Each scenario should be directly translatable into a test without interpretation.

## File Organization

```
docs/features/
  [domain]/
    index.md              # Index of features in this domain
    [behavior].feature    # One file per user-facing behavior
```

Group by domain (capture, processing, enqueue, auth, etc.), not by technical layer.

## Scenario Quality Standard

A scenario is well-written if a developer who hasn't read the requirements can implement it correctly from the scenario alone.

| Good | Bad |
|------|-----|
| `Then the response status is 201` | `Then it succeeds` |
| `And the response body contains a field "id" matching pattern "^[0-9a-f-]{36}$"` | `And an ID is returned` |
| `And the image is stored at the configured volume path` | `And the image is saved` |
| `Then the response status is 422` | `Then there is an error` |

## Template

```gherkin
Feature: [Feature Name]

  Background:
    Given [precondition that applies to all scenarios in this file]

  Scenario: [Happy path — title in plain English]
    Given [initial state]
    When [action taken]
    Then [expected outcome]
    And [additional assertion]

  Scenario: [Error case — be specific about the error]
    Given [state that triggers the error]
    When [action taken]
    Then [specific error response]
    And [system state is unchanged / recovery path]
```

## Writing Rules

**One behavior per scenario.** Don't chain multiple actions. Test one thing.

**Name the scenario from the user's perspective.** "Uploading a file with invalid JSON" not "Test error case 3."

**Be concrete in Given.** Name specific values: `"counties-1900.geojson" containing 42 features` not `a valid GeoJSON file`.

**Be specific in Then.** Exact status codes, exact field names, exact patterns.

**Cover all error states.** For every happy path, write at least the primary failure modes: missing input, invalid input, system unavailable.

## Example

```gherkin
Feature: Camera capture

  Background:
    Given the camera capture service is running
    And the user has a valid API token

  Scenario: Capturing a document with the camera
    Given the camera viewfinder is active
    And a document is held in frame with visible edges
    When the user presses the capture button
    Then the system returns a 201 response
    And the response body contains a capture ID
    And the image is stored on the local image volume

  Scenario: Capture with no document in frame
    Given the camera viewfinder is active
    And no document is detected in frame
    When the user presses the capture button
    Then the system returns a 422 response
    And the response body contains error code "NO_DOCUMENT_DETECTED"
    And no image is written to the volume

  Scenario: Capture with camera permission denied
    Given the browser has denied camera access
    When the capture page loads
    Then the viewfinder is replaced with an error state
    And the error message reads "Camera access is required. Enable it in browser settings."
    And the capture button is disabled
```

## Tagging

Use tags sparingly. Tag for meaningful filtering only.

```gherkin
@wip          # In progress, not yet implemented
@skip         # Known failing, deferred
@slow         # Integration test that hits external services
```

Don't tag by domain (redundant with folder structure) or priority (that's requirements.md's job).
