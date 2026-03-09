# TypeScript Best Practices

## Strict Mode

Always enable in `tsconfig.json`:

```json
{ "compilerOptions": { "strict": true } }
```

This enables `strictNullChecks`, `noImplicitAny`, and more.

## Types and Interfaces

```typescript
// Prefer interfaces for object shapes (open/extensible)
interface User {
  id: string;
  name: string;
  email: string;
  role: "admin" | "user";
}

// Use type for unions, intersections, mapped types
type Result<T> = { ok: true; data: T } | { ok: false; error: string };
type Partial<T> = { [K in keyof T]?: T[K] };

// Use readonly to prevent mutation
interface Config {
  readonly apiUrl: string;
  readonly timeout: number;
}
```

## Nullability

```typescript
// Use optional chaining and nullish coalescing
const name = user?.profile?.displayName ?? "Anonymous";

// Type guards for narrowing
function isError(val: unknown): val is Error {
  return val instanceof Error;
}

// Never use `as` to lie about types — use type guards instead
// ❌ const user = data as User;
// ✅ if (isUser(data)) { use data }
```

## Async/Error Handling

```typescript
// Use Result types to make errors explicit
async function fetchUser(id: string): Promise<Result<User>> {
  try {
    const data = await api.get(`/users/${id}`);
    return { ok: true, data };
  } catch (err) {
    return {
      ok: false,
      error: err instanceof Error ? err.message : "Unknown error",
    };
  }
}

// Handle results explicitly at the call site
const result = await fetchUser(id);
if (!result.ok) {
  logger.error(result.error);
  return;
}
const user = result.data; // narrowed to User
```

## Generics

```typescript
// Write reusable utilities with generics
function groupBy<T>(items: T[], key: keyof T): Record<string, T[]> {
  return items.reduce(
    (acc, item) => {
      const group = String(item[key]);
      return { ...acc, [group]: [...(acc[group] ?? []), item] };
    },
    {} as Record<string, T[]>,
  );
}
```

## Testing (Jest/Vitest)

```typescript
import { describe, it, expect, vi, beforeEach } from "vitest";

describe("UserService", () => {
  let service: UserService;
  let mockDb: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    mockDb = vi.fn();
    service = new UserService({ db: mockDb });
  });

  it("returns null when user does not exist", async () => {
    mockDb.mockResolvedValue(null);
    const result = await service.findById("missing-id");
    expect(result).toBeNull();
  });
});
```
