# TODO: Functions

Goal:

```
fn foo(bar, baz) {
    return bar + baz
}
```

All parameters and the return value are floats (no void functions, no other
types). `fn` keyword → function name → parameter list in parens → body in
curly braces. Newline still ends a statement.

## Design decisions (resolved with the author)

- **Scoping: functions are isolated.** A body sees only its parameters (and
  its own `var` locals), never global variables — data gets in only through
  parameters. Implication: a call evaluates the body in a **fresh
  Environment** seeded with just the bound params, not the global env.
  Subtlety to remember: "no globals" means no global *variables* — the
  **function table is still globally visible**, otherwise recursion and
  mutual calls are impossible. So: fresh variable scope per call, shared
  function table.
- **Namespaces: functions and variables cannot share a name.** Declaring a
  function whose name is an existing variable (or vice versa) is an error.
  Implication: name checks must consult **both** the variable env and the
  function table, even though they're stored separately.
- **Missing `return` is an error.** A function whose body finishes without
  returning is invalid. Open sub-decision — *when* to detect it:
  - **Static** (a small semantic pass): tractable right now because there is
    no control flow, so "the body contains no reachable return" is a simple
    structural check. Would be the project's first semantic-analysis pass.
  - **Runtime**: body evaluation completes without hitting a return →
    `RUNTIME_ERROR`. Low effort, fits the current eval-only model, but only
    fires when the function is actually called.
  - Lean: static, as a first real semantic check — but runtime is a fine
    starting point. Decide before writing the eval code.
- **No nested functions (for now).** `fn` may appear only at the top level.
  This falls out of the grammar for free: parse function bodies with a
  dedicated `parse_block` that accepts return/var/assign/expression but NOT
  `fn`. By the same split, `return` is body-only — a top-level `return` is a
  parse error because `parse_program` won't accept it.
- **No brace/newline formatting rules.** `{` and `}` may sit anywhere;
  newlines around them are insignificant. Implication: block parsing skips
  newlines liberally around and inside braces (same blank-line skipping as
  `parse_program`).
- **REPL handles multi-line function declarations.** Bodies span lines, so
  the REPL must accumulate input until braces balance before parsing.
  Strategy: track brace depth across `treadline()` reads; while a definition
  is open (depth > 0), show a continuation prompt and append lines into one
  buffer; parse+eval only when depth returns to 0. NOTE this collides with
  the current per-line `@pool()` + free-each-line lifetime — the accumulated
  buffer and any stored function AST must now outlive a single line.

## Lexer

- [ ] New tokens: `FN`, `RETURN`, `L_BRACE` (`{`), `R_BRACE` (`}`), `COMMA`
- [ ] Extend keyword lookup: `"fn"` → `FN`, `"return"` → `RETURN`
- [ ] Tests: token stream of a full `fn` declaration

## AST + Parser

- [ ] New statement kinds (same tagged-union pattern):
      - function declaration: name + parameter names + body (statement list)
      - return statement: expression
- [ ] New expression kind: call — callee name + argument expression list
- [ ] `parse_statement` (top level): add the `FN` arm (name, `(` params `)`,
      `{` body `}`). Does NOT accept `return`.
- [ ] `parse_block` (function body): statements until `R_BRACE`, skipping
      newlines. Accepts return/var/assign/expression but NOT `fn` (enforces
      no-nested-functions and body-only `return` structurally).
- [ ] Call parsing in `parse_factor`: `IDENTIFIER` followed by `(` (same
      peek trick as assignment), comma-separated args until `R_PAREN`
- [ ] `free_statement` / `free_expression` for the new node kinds — bodies
      and arg lists are Lists, so the `defer catch` error paths must free
      partially built lists (the leak-detecting tests will catch omissions)
- [ ] Parser-shape tests + error-path tests (missing `)`, missing `}`,
      missing name, `fn` inside a body, top-level `return`, ...)

## Evaluation

- [ ] Function table: name → function-declaration AST node (a second
      HashMap alongside the variable Environment).
- [ ] Function declaration: store the function; **error if the name already
      exists as either a variable OR a function** (namespace rule). Likewise
      `var` / assignment must reject names that collide with a function.
- [ ] Call expression: undefined function → runtime error; argument-count
      mismatch → runtime error; build a **fresh Environment** containing only
      the params bound to the evaluated args (isolated scope), then evaluate
      the body against that env + the shared function table.
- [ ] `return`: needs a mechanism to stop evaluating the body mid-way and
      carry the value out of the statement list. Design before coding — one
      option that fits the existing style is a `RETURN` signal plus a
      return-value side channel (mirroring the `Error` side channel, since
      C3 faults carry no payload); another is a `{bool returned; float value}`
      result threaded out of block/statement eval. Weigh both.
- [ ] Missing-return enforcement per the sub-decision above (static pass vs
      runtime detection).
- [ ] Recursion: supported for free once the function is in the table before
      it's called; with isolated scope, recursive state only flows through
      params and return values. Add a call-depth limit to turn stack
      overflow into a clean runtime error.
- [ ] Lifetime: called functions outlive the statement that declared them,
      and the REPL currently frees each line's AST after evaluating it —
      storing a pointer to a freed body would be use-after-free. Decide
      ownership (e.g. the function table owns the declaration AST) before
      wiring up the REPL.
- [ ] End-to-end tests: simple call, call inside expressions, multiple
      params, isolated-scope check (a body cannot see a global var),
      namespace-collision errors, arg-count mismatch, undefined function,
      missing return, recursion.

## Optional: first semantic pass

- [ ] If missing-return (and possibly namespace collisions) move to a static
      check, this introduces a real semantic-analysis phase between parse and
      eval. Small now, but worth structuring cleanly — it will grow when
      control flow arrives.

## Leftovers from the variables milestone

- [ ] Expression statements don't enforce a NEW_LINE/EOF terminator:
      `1 2` parses as two statements on one line in file mode, and the REPL
      silently ignores trailing tokens after a complete expression
- [ ] Error-reporting split: parser errors are silent + `Error` side
      channel, but runtime errors print directly from eval.c3 (the REPL's
      eval `catch` is deliberately empty). Consider migrating eval to the
      `Error` struct style — would also enable line info in messages
- [ ] File mode silently truncates input larger than the fixed 2048-byte
      buffer in `read_file`
