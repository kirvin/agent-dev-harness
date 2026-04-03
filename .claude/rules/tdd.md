# TDD

All feature and bug implementation follows Red-Green-Refactor. Exceptions to this are for:

1.  Creating database migrations
2.  Creating or modifying Docker files

Other than the items listed above, no exceptions to this rule.

## The Three Steps

1. **Red** — Write a failing test that encodes one acceptance criterion. Run it. Confirm it fails.
2. **Green** — Write the minimum code to make it pass. Run it. Confirm it passes.
3. **Refactor** — Clean up, keeping tests green.

Never write implementation code before a failing test exists for it.

## Mandatory skill activations

When starting any implementation task:
- Load `ce:writing-tests` to choose the right test type and avoid anti-patterns
- Load `ce:verification-before-completion` before claiming any task is done

## What counts as a test

| Task type | Minimum test coverage |
|-----------|----------------------|
| GraphQL mutation/query | Integration test: resolver returns correct shape and errors |
| Business logic function | Unit test: all happy paths + error cases |
| Database interaction | Integration test: against a real DB (test DB or in-memory) |
| Auth / JWT | Integration test: valid token grants access, invalid token is rejected |

## Red flags — stop and write tests first if you catch yourself

- Writing a resolver before a test file exists
- Adding a route/mutation and immediately running the server to test it manually
- Saying "I'll add tests after" — this never happens
