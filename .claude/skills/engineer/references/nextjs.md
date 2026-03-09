# Next.js Best Practices

## App Router Architecture

```
app/
├── layout.tsx              # Root layout (HTML shell, global providers)
├── page.tsx                # Homepage (/)
├── (marketing)/            # Route group — doesn't affect URL
│   ├── about/page.tsx
│   └── pricing/page.tsx
├── (app)/                  # Route group for authenticated routes
│   ├── layout.tsx          # Auth check, app shell
│   ├── dashboard/
│   │   ├── page.tsx
│   │   └── loading.tsx     # Streaming skeleton
│   └── users/
│       ├── page.tsx
│       └── [id]/
│           ├── page.tsx
│           └── error.tsx   # Error boundary
├── api/                    # Route Handlers (REST endpoints)
│   └── users/
│       └── route.ts
└── _components/            # Shared components (underscore = not a route)
```

---

## Server vs. Client Components

**Default to Server Components.** Add `'use client'` only when needed.

| Use Server Component     | Use Client Component (`'use client'`) |
| ------------------------ | ------------------------------------- |
| Data fetching            | Event handlers (onClick, onChange)    |
| Access backend resources | useState, useEffect, hooks            |
| Keep secrets server-side | Browser APIs (localStorage, etc.)     |
| Reduce JS bundle         | Real-time updates                     |

```tsx
// ✅ Server Component — async, fetches directly, no client JS
// app/users/page.tsx
export default async function UsersPage() {
  const users = await db.query.users.findMany();
  return <UserList users={users} />;
}

// ✅ Client Component — only where interactivity is needed
("use client");
export function SearchBar({ onSearch }: { onSearch: (q: string) => void }) {
  const [query, setQuery] = useState("");
  return (
    <input
      value={query}
      onChange={(e) => {
        setQuery(e.target.value);
        onSearch(e.target.value);
      }}
    />
  );
}
```

**Push `'use client'` to the leaves** — wrap only the interactive parts, not entire page sections.

---

## Data Fetching

```tsx
// ✅ Fetch in Server Components — parallel, deduped automatically
export default async function Page({ params }: { params: { id: string } }) {
  // These run in parallel
  const [user, posts] = await Promise.all([
    getUser(params.id),
    getUserPosts(params.id),
  ]);
  return <Profile user={user} posts={posts} />;
}

// ✅ fetch() is extended — supports caching and revalidation
const data = await fetch("https://api.example.com/data", {
  next: { revalidate: 3600 }, // ISR: revalidate every hour
});

const fresh = await fetch("https://api.example.com/live", {
  cache: "no-store", // Always fresh (SSR)
});

// ✅ Server Actions for mutations
("use server");
export async function createUser(formData: FormData) {
  const name = formData.get("name") as string;
  await db.insert(users).values({ name });
  revalidatePath("/users");
}
```

---

## Route Handlers (API Routes)

```ts
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from "next/server";

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  try {
    const user = await getUser(params.id);
    if (!user) {
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }
    return NextResponse.json(user);
  } catch (error) {
    console.error("GET /api/users/[id]:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 },
    );
  }
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: { id: string } },
) {
  const body = await request.json();
  // validate, update, return
}
```

---

## Metadata and SEO

```tsx
// Static metadata
export const metadata: Metadata = {
  title: "Dashboard | MyApp",
  description: "Manage your account and settings",
};

// Dynamic metadata
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const product = await getProduct(params.id);
  return {
    title: `${product.name} | MyApp`,
    openGraph: {
      images: [product.imageUrl],
    },
  };
}
```

---

## Loading and Error States

```tsx
// app/dashboard/loading.tsx — shown instantly while page loads
export default function Loading() {
  return <DashboardSkeleton />; // Match layout of the actual page
}

// app/dashboard/error.tsx — error boundary for this segment
("use client");
export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}

// app/not-found.tsx — shown for 404s
export default function NotFound() {
  return <h2>Page not found</h2>;
}
```

---

## Middleware

```ts
// middleware.ts — runs on the Edge before every request
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const token = request.cookies.get("session")?.value;

  if (!token && request.nextUrl.pathname.startsWith("/app")) {
    return NextResponse.redirect(new URL("/login", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/app/:path*", "/api/:path*"],
};
```

---

## Environment Variables

```bash
# .env.local
DATABASE_URL=postgres://...        # Server-only (never exposed to client)
NEXT_PUBLIC_API_URL=https://...    # Exposed to client (NEXT_PUBLIC_ prefix)
```

```ts
// Validate env vars at startup with zod
const env = z
  .object({
    DATABASE_URL: z.string().url(),
    NEXT_PUBLIC_API_URL: z.string().url(),
  })
  .parse(process.env);
```

---

## Performance Checklist

- [ ] Use `next/image` for all images (auto-optimization, lazy loading)
- [ ] Use `next/link` for all internal navigation (prefetching)
- [ ] Use `next/font` to load custom fonts (zero layout shift)
- [ ] Dynamic import heavy components: `dynamic(() => import('./HeavyChart'))`
- [ ] Add `loading.tsx` and `error.tsx` to all major route segments
- [ ] Use `generateStaticParams` for static rendering of dynamic routes
- [ ] Analyze bundle: `ANALYZE=true next build`
