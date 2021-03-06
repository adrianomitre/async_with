# Changelog

## v0.3.0

### Enhancements

  * Support `use AsyncWith` outside of a module. This allows interactive IEx sessions.
  * Raise `CompilerError` instead of `ArgumentError` when the `async` macro is not used with `with`.
  * Raise `CompilerError` errors when no clauses nor blocks are provided.
  * Export formatter configuration via `.formatter.exs`.
  * Support single line usage (i.e. `async with a <- 1, do: a`).
  * Re-throw uncaught values (i.e. `async with _ <- throw(:foo), do: :ok`).
  * Re-raise unrescued errors (i.e. `async with _ <- raise("ops"), do: :ok`).

## v0.2.2

### Enhancements

  * Print a warning message when using `else` clauses that will never match because all patterns in `async with` will always match.

### Bug fixes

  * Fix compiler warnings produced when one of the `async with` clauses followed an always match pattern (i.e. `a <- 1`).

## v0.2.1

### Enhancements

  * Correct documentation regarding `@async_with_timeout` attribute.

## v0.2.0

### Enhancements

  * Optimize implementation.
  * Use same timeout exit format as `Task`.

### Bug fixes

  * Ensure asynchronous execution of all clauses as soon as their dependencies are fulfilled.

### Deprecations

  * `DOT` is removed.
  * `DependencyGraph` is removed.
  * `DependencyGraph.Vertex` is removed.
  * `Macro.DependencyGraph` is removed.
  * `Macro.OutNeighbours` is removed.
  * `Macro.Vertex` is removed.
  * `Clause` is now private.
  * `Macro` is now private.
