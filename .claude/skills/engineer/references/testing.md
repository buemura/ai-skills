# Testing Patterns Reference

## Universal Testing Principles

### AAA Pattern (Arrange / Act / Assert)

Structure every test in three clear phases:

```
// Arrange: set up state and inputs
// Act: call the code under test
// Assert: verify the outcome
```

### Test Naming Convention

Names should describe behavior, not implementation:

- ✅ `test_returns_error_when_email_is_duplicate`
- ❌ `test_create_user_2`

Format: `test_[unit]_[scenario]_[expected]`

### Test Isolation

- Each test must be independent — no ordering dependencies
- Reset shared state in `beforeEach` / `setUp`
- Never share mutable objects between tests

---

## Mocking Strategy

**Mock at the boundary** — mock external dependencies (DB, HTTP, filesystem), not internal logic.

```typescript
// ✅ Mock the HTTP client, not internal utilities
const mockHttp = { get: vi.fn().mockResolvedValue({ data: user }) };
const service = new UserService(mockHttp);

// ❌ Don't mock implementation details of the unit you're testing
```

**For database tests:** use an in-memory DB or test transaction that gets rolled back.

**For time-sensitive tests:** always mock `Date.now()` / `datetime.now()`.

---

## Integration vs Unit Tests

|             | Unit Test                               | Integration Test                      |
| ----------- | --------------------------------------- | ------------------------------------- |
| Speed       | Fast (<10ms)                            | Slower (100ms+)                       |
| Scope       | Single function/class                   | Multiple layers (DB, HTTP)            |
| Isolation   | Full mocking                            | Real dependencies                     |
| When to use | Pure logic, algorithms, transformations | Repositories, API handlers, workflows |

---

## Framework Quick Reference

### pytest (Python)

```python
@pytest.fixture(autouse=True)
def reset_db(db):
    yield
    db.rollback()

@pytest.mark.asyncio
async def test_async_operation():
    result = await async_fn()
    assert result == expected
```

### Jest / Vitest (JavaScript/TypeScript)

```typescript
beforeEach(() => vi.clearAllMocks());
afterEach(() => vi.restoreAllMocks());

// Spy without replacing
const spy = vi.spyOn(service, "method");
expect(spy).toHaveBeenCalledWith(expectedArg);
```

### Go

```go
func TestFeature(t *testing.T) {
    t.Run("returns error on invalid input", func(t *testing.T) {
        _, err := Process("")
        if err == nil {
            t.Fatal("expected error, got nil")
        }
    })
}
```

---

## Coverage Guidelines

- Aim for **meaningful coverage**, not 100% line coverage
- Always cover: happy path, main error paths, boundary conditions
- Skip testing: generated code, trivial getters/setters, framework boilerplate
- A missed test is better than a meaningless test
