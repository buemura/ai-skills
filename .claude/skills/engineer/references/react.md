# React Best Practices

## Component Design

### Keep components focused

A component should do one thing. If it's fetching data, managing complex state, AND rendering — split it.

```tsx
// ✅ Separate concerns: container vs. presentational
function UserProfilePage({ userId }: { userId: string }) {
  const { data: user, isLoading, error } = useUser(userId);

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;
  if (!user) return null;

  return <UserProfile user={user} />;
}

// Pure presentational — easy to test and reuse
function UserProfile({ user }: { user: User }) {
  return (
    <div>
      <h1>{user.name}</h1>
      <p>{user.email}</p>
    </div>
  );
}
```

### Component naming and files

- One component per file; filename matches component name
- Use PascalCase for components, camelCase for hooks
- Co-locate styles, tests, and subcomponents with the component

```
components/
└── UserCard/
    ├── UserCard.tsx
    ├── UserCard.test.tsx
    └── UserCard.module.css   (or styles.ts for CSS-in-JS)
```

---

## Hooks

### Custom hooks extract logic, not just state

```tsx
// ✅ Custom hook encapsulates all logic for a feature
function useUser(userId: string) {
  return useQuery({
    queryKey: ["user", userId],
    queryFn: () => api.getUser(userId),
    staleTime: 5 * 60 * 1000,
  });
}

// ✅ Keep hooks at top level — never inside conditions or loops
function Component() {
  const [count, setCount] = useState(0); // ✅ Always called

  // ❌ Never:
  if (condition) {
    const [value, setValue] = useState("");
  }
}
```

### useEffect rules

```tsx
// ✅ Synchronize with external systems only
useEffect(() => {
  const subscription = eventBus.subscribe(handleEvent);
  return () => subscription.unsubscribe(); // Always clean up
}, [handleEvent]);

// ❌ Don't use useEffect for derived state
// ❌ Don't use useEffect for event handlers
// ❌ Don't use useEffect to fetch on mount — use React Query / SWR instead
```

---

## State Management

### Colocate state as close to its use as possible

```
useState      →  component-local state
useContext    →  shared state across a subtree (theme, auth)
Zustand/Jotai →  global client state (UI preferences, cart)
React Query   →  server state (data from APIs)
```

### Avoid prop drilling — use composition instead

```tsx
// ✅ Composition: pass children to avoid drilling
function Layout({
  sidebar,
  children,
}: {
  sidebar: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <div className="layout">
      <aside>{sidebar}</aside>
      <main>{children}</main>
    </div>
  );
}
```

---

## Performance

Only optimize when you have a measured problem. Premature optimization adds complexity.

```tsx
// useMemo: memoize expensive computations
const sortedItems = useMemo(
  () => items.sort((a, b) => a.name.localeCompare(b.name)),
  [items],
);

// useCallback: stabilize function references passed to memoized children
const handleClick = useCallback(
  (id: string) => {
    dispatch({ type: "SELECT", id });
  },
  [dispatch],
);

// React.memo: skip re-render when props haven't changed
const ExpensiveList = React.memo(function ExpensiveList({ items }: Props) {
  return (
    <ul>
      {items.map((item) => (
        <li key={item.id}>{item.name}</li>
      ))}
    </ul>
  );
});

// Lazy loading for code splitting
const HeavyChart = React.lazy(() => import("./HeavyChart"));
```

---

## Forms

Use a form library for anything beyond trivial forms:

```tsx
// React Hook Form (preferred — minimal re-renders)
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(schema),
  });

  const onSubmit = (data: z.infer<typeof schema>) => {
    // data is fully typed and validated
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register("email")} />
      {errors.email && <p>{errors.email.message}</p>}
      <button type="submit">Login</button>
    </form>
  );
}
```

---

## Accessibility (a11y)

```tsx
// ✅ Use semantic HTML
<button onClick={handle}>Submit</button>   // not <div onClick={...}>
<nav>, <main>, <header>, <section>         // not all <div>

// ✅ Always provide accessible labels
<input aria-label="Search products" />
<img src={src} alt="User avatar for John Doe" />

// ✅ Manage focus for dynamic content
const ref = useRef<HTMLDivElement>(null);
useEffect(() => { ref.current?.focus(); }, [isOpen]);
```

---

## Testing (React Testing Library)

```tsx
import { render, screen, userEvent } from "@testing-library/react";

// ✅ Query by role/label — tests behavior, not implementation
test("submits form with user data", async () => {
  const onSubmit = vi.fn();
  render(<LoginForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByLabelText("Email"), "user@example.com");
  await userEvent.type(screen.getByLabelText("Password"), "password123");
  await userEvent.click(screen.getByRole("button", { name: "Login" }));

  expect(onSubmit).toHaveBeenCalledWith({
    email: "user@example.com",
    password: "password123",
  });
});

// ✅ Test what users see, not internal state
// ❌ Don't: wrapper.instance().setState(...)
// ❌ Don't: expect(component.find('div').props().className).toBe(...)
```
