# Go Best Practices

## Project Structure

```
myapp/
├── cmd/
│   └── server/
│       └── main.go          # Entry point — thin, just wires things up
├── internal/                # Private packages — not importable externally
│   ├── domain/              # Core types and interfaces
│   ├── service/             # Business logic
│   ├── repository/          # Data access
│   └── handler/             # HTTP/gRPC handlers
├── pkg/                     # Public reusable packages
├── config/
└── go.mod
```

Keep `main.go` thin — it should only wire up dependencies and start the server.

---

## Error Handling

Go errors are values. Treat them seriously.

```go
// ✅ Wrap errors with context using %w
func getUser(id string) (*User, error) {
    user, err := db.Query(id)
    if err != nil {
        return nil, fmt.Errorf("getUser %s: %w", id, err)
    }
    return user, nil
}

// ✅ Sentinel errors for known conditions
var (
    ErrNotFound   = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
)

// ✅ Check with errors.Is for wrapped errors
if errors.Is(err, ErrNotFound) {
    http.Error(w, "not found", http.StatusNotFound)
    return
}

// ✅ Custom error types for rich context
type ValidationError struct {
    Field   string
    Message string
}
func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %s", e.Field, e.Message)
}

// ❌ Never ignore errors
user, _ := getUser(id)  // BAD
```

---

## Interfaces

Define interfaces at the **consumer**, not the producer. Keep them small.

```go
// ✅ Small interface at point of use
type UserStore interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

// The concrete type can implement many interfaces without knowing about them
type PostgresUserStore struct { db *sql.DB }

// ❌ Don't define giant interfaces with 20 methods
// ❌ Don't put interfaces in the same package as the implementation
```

---

## Context

Always propagate `context.Context` as the **first parameter**.

```go
func (s *UserService) GetUser(ctx context.Context, id string) (*User, error) {
    // Pass ctx to all downstream calls
    return s.store.FindByID(ctx, id)
}

// Check for cancellation in long-running work
for _, item := range items {
    select {
    case <-ctx.Done():
        return ctx.Err()
    default:
        process(item)
    }
}
```

---

## Concurrency

```go
// Use errgroup for concurrent tasks with error handling
import "golang.org/x/sync/errgroup"

g, ctx := errgroup.WithContext(ctx)

g.Go(func() error {
    return fetchUsers(ctx)
})
g.Go(func() error {
    return fetchOrders(ctx)
})

if err := g.Wait(); err != nil {
    return fmt.Errorf("parallel fetch: %w", err)
}

// Protect shared state with sync.Mutex
type Cache struct {
    mu    sync.RWMutex
    items map[string]string
}
func (c *Cache) Get(key string) (string, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    v, ok := c.items[key]
    return v, ok
}
```

---

## Structs and Constructors

```go
// Use constructor functions for validation and defaults
func NewUser(name, email string) (*User, error) {
    if name == "" {
        return nil, &ValidationError{Field: "name", Message: "required"}
    }
    if !isValidEmail(email) {
        return nil, &ValidationError{Field: "email", Message: "invalid format"}
    }
    return &User{
        ID:        newUUID(),
        Name:      name,
        Email:     email,
        CreatedAt: time.Now(),
    }, nil
}

// Use functional options for optional config
type ServerOption func(*Server)

func WithTimeout(d time.Duration) ServerOption {
    return func(s *Server) { s.timeout = d }
}

func NewServer(addr string, opts ...ServerOption) *Server {
    s := &Server{addr: addr, timeout: 30 * time.Second}
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

---

## Testing

```go
// Table-driven tests are idiomatic Go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"missing @", "userexample.com", true},
        {"empty string", "", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validateEmail(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("validateEmail(%q) error = %v, wantErr %v", tt.input, err, tt.wantErr)
            }
        })
    }
}

// Use interfaces + test doubles instead of monkey-patching
type mockUserStore struct {
    users map[string]*User
}
func (m *mockUserStore) FindByID(_ context.Context, id string) (*User, error) {
    u, ok := m.users[id]
    if !ok {
        return nil, ErrNotFound
    }
    return u, nil
}

// Use testify for cleaner assertions (if project already uses it)
assert.NoError(t, err)
assert.Equal(t, expected, actual)
require.NotNil(t, result)  // require stops the test immediately
```

---

## HTTP Handlers

```go
// Keep handlers thin — delegate to services
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
    id := r.PathValue("id")

    user, err := h.service.GetUser(r.Context(), id)
    if err != nil {
        if errors.Is(err, ErrNotFound) {
            http.Error(w, "user not found", http.StatusNotFound)
            return
        }
        h.logger.Error("get user", "error", err, "id", id)
        http.Error(w, "internal server error", http.StatusInternalServerError)
        return
    }

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(user)
}
```

---

## Linting and Tooling

Always run before committing:

```bash
go vet ./...                     # Built-in static analysis
golangci-lint run                # Comprehensive linting
go test ./... -race              # Race condition detection
go test ./... -cover             # Coverage report
```

Key linters to enable: `errcheck`, `staticcheck`, `gosimple`, `ineffassign`, `unused`.
