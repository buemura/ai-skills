# Python Best Practices

## Type Hints (always use in new code)

```python
from typing import Optional, List, Dict, Any
from collections.abc import Sequence

def process_items(
    items: Sequence[str],
    limit: Optional[int] = None,
) -> List[str]:
    ...
```

Use `from __future__ import annotations` for forward references.

## Idiomatic Python

```python
# Use list/dict/set comprehensions over map/filter
names = [u.name for u in users if u.active]

# Use enumerate instead of range(len(...))
for i, item in enumerate(items):
    ...

# Use zip for parallel iteration
for key, val in zip(keys, values):
    ...

# Use dataclasses or Pydantic for structured data (not bare dicts)
from dataclasses import dataclass

@dataclass
class Config:
    host: str
    port: int = 8080
    debug: bool = False
```

## Error Handling

```python
# Define custom exceptions for domain errors
class UserNotFoundError(ValueError):
    def __init__(self, user_id: int):
        super().__init__(f"User {user_id} not found")
        self.user_id = user_id

# Use contextlib for resource management
from contextlib import contextmanager

@contextmanager
def open_connection(url: str):
    conn = connect(url)
    try:
        yield conn
    finally:
        conn.close()
```

## Async Python

```python
import asyncio
from asyncio import TaskGroup

# Concurrent execution
async def fetch_all(urls: list[str]) -> list[str]:
    async with TaskGroup() as tg:
        tasks = [tg.create_task(fetch(url)) for url in urls]
    return [t.result() for t in tasks]

# Always use async context managers for resources
async with aiohttp.ClientSession() as session:
    async with session.get(url) as response:
        return await response.json()
```

## Testing (pytest)

```python
import pytest

# Fixtures for setup/teardown
@pytest.fixture
def db_session():
    session = create_test_session()
    yield session
    session.rollback()
    session.close()

# Parametrize for multiple cases
@pytest.mark.parametrize("input,expected", [
    ("hello", "HELLO"),
    ("", ""),
    ("123", "123"),
])
def test_uppercase(input, expected):
    assert uppercase(input) == expected

# Use pytest.raises for error testing
def test_raises_on_invalid_input():
    with pytest.raises(ValueError, match="must be positive"):
        process(-1)
```
