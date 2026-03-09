# Documentation Best Practices

Good documentation is written for a specific reader with a specific goal. Before writing, ask:
**Who is reading this, and what are they trying to do?**

---

## Four Types of Documentation

| Type             | Purpose                            | Reader's goal            |
| ---------------- | ---------------------------------- | ------------------------ |
| **Tutorial**     | Learning-oriented, guided steps    | "Help me get started"    |
| **How-to guide** | Task-oriented, practical steps     | "Help me do X"           |
| **Reference**    | Information-oriented, precise      | "Tell me about Y"        |
| **Explanation**  | Understanding-oriented, conceptual | "Help me understand why" |

Don't mix types in a single document. Each type is a different writing mode.

---

## Code Documentation

### Functions and Methods

Document the **contract**, not the implementation:

- What does it do? (briefly)
- What are the inputs and their constraints?
- What does it return?
- What errors can it raise/return?
- Any important side effects?

```python
def transfer_funds(
    from_account: str,
    to_account: str,
    amount: Decimal,
) -> TransferResult:
    """Transfer funds between accounts atomically.

    Args:
        from_account: Source account ID. Must exist and have sufficient balance.
        to_account: Destination account ID. Must exist.
        amount: Amount to transfer. Must be positive.

    Returns:
        TransferResult with transaction ID and updated balances.

    Raises:
        InsufficientFundsError: If from_account balance < amount.
        AccountNotFoundError: If either account does not exist.

    Note:
        Transfer is atomic — either both sides update or neither does.
    """
```

```typescript
/**
 * Validates a JWT token and returns the decoded payload.
 *
 * @param token - Raw JWT string from Authorization header
 * @returns Decoded payload if valid
 * @throws {TokenExpiredError} If token has expired
 * @throws {InvalidTokenError} If token is malformed or signature is invalid
 */
function verifyToken(token: string): JwtPayload { ... }
```

```go
// FindByEmail returns the user with the given email address.
// Returns ErrNotFound if no user exists with that email.
// The email comparison is case-insensitive.
func (r *UserRepository) FindByEmail(ctx context.Context, email string) (*User, error) {
```

### When NOT to comment

```python
# ❌ Noise — the code says this already
# Increment counter by 1
counter += 1

# ❌ Lying comment — worse than no comment
# Returns the user
def get_admin(id):  # Actually returns an admin, not any user
    ...

# ✅ Explain the why, not the what
# Use ceiling division so the last page is never empty
page_count = -(-total // page_size)
```

---

## README Structure

A good README answers these questions in order:

```markdown
# Project Name

One sentence: what does this do and who is it for?

## Quick Start

The minimum steps to go from zero to working. (< 5 steps ideally)

## Installation

Prerequisites, setup steps, environment variables.

## Usage

Most common use cases with real examples.
Code blocks for every command. Don't describe what to type — show it.

## Configuration

All options, their types, defaults, and what they do.

## Development

How to run locally, run tests, contribute.

## Architecture (optional)

High-level explanation for contributors. Link to deeper docs.
```

**Rules for READMEs:**

- Code blocks for every terminal command and code sample
- Assume the reader is smart but unfamiliar with your codebase
- Keep the Quick Start genuinely quick — cut anything optional
- Test your README with a fresh clone before publishing

---

## API Documentation

```yaml
# Document each endpoint with:
# - Method + path
# - What it does (one sentence)
# - Auth requirements
# - Request body / query params with types and validation rules
# - Response shape with status codes
# - Error responses with error codes

GET /api/users/{id}
  Summary: Retrieve a user by ID
  Auth: Bearer token required

  Path params:
    id (string, required): UUID of the user

  Responses:
    200: User object
      { id, name, email, createdAt }
    404: User not found
      { error: "USER_NOT_FOUND" }
    401: Missing or invalid token
```

Use OpenAPI/Swagger for large APIs — it generates interactive docs and client SDKs.

---

## ADRs (Architecture Decision Records)

When making a significant technical decision, write a short ADR. Future teammates (including future you) will thank you.

```markdown
# ADR-0012: Use PostgreSQL over MongoDB for primary datastore

**Date:** 2024-03-15  
**Status:** Accepted

## Context

We need to choose a primary database. Our data is relational (users, orders, products)
with complex queries and strict consistency requirements.

## Decision

Use PostgreSQL.

## Rationale

- Our data model has well-defined relationships and benefits from foreign keys and joins
- ACID transactions are required for order processing
- The team has existing PostgreSQL expertise
- MongoDB's flexible schema offers no advantage for our known, stable domain model

## Consequences

- We must manage schema migrations (using Flyway)
- Horizontal write scaling is harder than with MongoDB, but acceptable at current scale
- Full-text search will use pg_trgm or a separate search service
```

---

## Changelog (Keep a Changelog format)

```markdown
# Changelog

## [Unreleased]

### Added

- Support for bulk user imports via CSV

## [2.4.0] - 2024-03-10

### Added

- `GET /api/users/export` endpoint for downloading user data

### Changed

- Rate limiting now applies per IP instead of per account

### Fixed

- Fixed pagination returning duplicate records on the last page

### Deprecated

- `POST /api/v1/users` — use `/api/v2/users` instead (removes in 3.0)
```

Rules:

- Every user-visible change gets an entry
- Group by: Added / Changed / Deprecated / Removed / Fixed / Security
- Write for the reader, not the git blame: "Fixed pagination bug" not "Fixed off-by-one in UserRepository.paginate()"

---

## Inline Documentation Anti-Patterns

| Anti-pattern                  | Problem                             | Fix                                       |
| ----------------------------- | ----------------------------------- | ----------------------------------------- |
| Outdated comments             | Comments drift from code            | Delete or update on every change          |
| Commented-out code            | Nobody knows if it's safe to delete | Delete it; git history has it             |
| TODO comments without owners  | Accumulate forever                  | Add ticket reference: `// TODO(JIRA-123)` |
| Wall-of-text docstrings       | Skimmed and ignored                 | Use sections, short sentences, examples   |
| Over-documenting obvious code | Noise that buries signal            | Only document non-obvious behavior        |
