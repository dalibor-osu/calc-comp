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

- **Lexical scoping via an environment chain.** `Environment` is a scope
  struct holding both namespaces:
  `{ variables map, functions map (FnDeclarationStatement*), Environment* parent }`
  (null parent ⇒ global scope; the global scope's `functions` map is the
  function table). Each operation walks the chain differently:
  - **lookup** (variables and functions): own map, else parent,
    recursively; miss at the root → undefined reference
  - **declare** (`var`/`fn`/param): collision check + write in the **own
    scope only** — that asymmetry is what makes shadowing work
  - **assign** (`x = ...`): walk the chain to the scope that owns `x`,
    write there; not found anywhere → undefined reference. A body's
    `x = 5` where `x` is global **mutates the global**.
- **Calls are lexically scoped.** Function lookup returns both the
  declaration and the env it was found in — the found-env IS the
  definition env — and the call's fresh Environment parents to it (never
  the caller's env, which would be dynamic scoping). A scope can only find
  functions defined on its own chain, so a callee never sees an unrelated
  caller's locals. Future brace-blocks are just child envs too.
- **Local functions are supported.** `fn` inside a body registers in the
  current env's `functions` map and is callable only while that scope is
  on the chain. Safe without closures *only because functions are not
  values* (cannot be returned/stored), so a fn's defining env is always
  alive at call time — if functions ever become first-class, closures must
  be designed for real. `return` is body-only: `parse_block` accepts `fn`,
  top-level `parse_program` rejects `return`.
- **Namespaces: one namespace per scope, uniform shadowing.** Within a
  single scope a function and a variable cannot share a name (declarations
  check both maps of their own scope). Across scopes, ANY inner
  declaration may shadow ANY outer name — including a local `var f`
  shadowing an outer `fn f`.
- **Missing `return` is an error.** Detection timing still open:
  - **Static** (a small semantic pass): easy while there is no control
    flow — "body contains no return" is structural. Preferred; would be
    the first semantic-analysis pass.
  - **Runtime**: body evaluation finishes without a return →
    `RUNTIME_ERROR`. Lower effort, fine starting point.
  - Nested-fn subtlety either way: a `return` inside a local fn does NOT
    count for the enclosing body (`fn outer() { fn inner() { return 1 } }`
    → `outer` is missing a return). Scan each body independently, skipping
    nested `fn` bodies.
- **No brace/newline formatting rules.** `{`/`}` may sit anywhere; block
  parsing skips newlines liberally (same blank-line skipping as
  `parse_program`).
- **REPL handles multi-line declarations** by accumulating input until
  braces balance (track brace depth across `treadline()` reads,
  continuation prompt while depth > 0). NOTE: collides with the current
  per-line `@pool()` + free-each-line lifetime — the accumulated buffer
  and stored function ASTs must outlive a single line.

## Lexer

- [x] New tokens: `FN`, `RETURN`, `L_BRACE`, `R_BRACE`, `COMMA`
- [x] Keyword lookup: `"fn"` → `FN`, `"return"` → `RETURN`
- [x] Tests: token stream of a full `fn` declaration

## AST + Parser

- [x] New statement kinds: function declaration (name + parameter names +
      body statement list), return statement (expression)
- [x] New expression kind: call (callee name + argument expression list)
- [x] `parse_statement` (top level): `FN` arm; does not accept `return`
- [x] `parse_block` (function body): statements until `R_BRACE`, skipping
      newlines; accepts `return`, rejects top-level-only forms
- [x] Call parsing in `parse_factor`: `IDENTIFIER` followed by `(` (same
      peek trick as assignment), comma-separated args until `R_PAREN`
- [x] Allow `fn` inside `parse_block` (local functions) — drop the
      structural restriction; top level still rejects `return`
- [x] `free_statement` / `free_expression` for the new node kinds — bodies
      and arg lists are Lists, so `defer catch` error paths must free
      partially built lists (the leak-detecting tests enforce this)
- [x] Parser-shape tests + error-path tests (missing `)`, missing `}`,
      missing name, top-level `return`, ...; shape test: nested `fn`
      inside a body parses)

## Evaluation

- [x] Rework `Environment` per the scoping decision above: struct with
      `variables`, `functions` (store `FnDeclarationStatement*` — a
      by-value copy would share the param/body List storage with the AST
      and wreck ownership), `parent`. Methods encode the chain rules:
      `get` / `declare` / `assign` for variables; function lookup returns
      declaration + found-env. Scoping mechanics live in the environment;
      error decisions/messages stay in eval. Freeing a child env frees
      only its own maps, never the parent (`COPY_KEYS` applies to both
      maps).
- [x] Function declaration eval: register in the **current** env's
      `functions` map; collision check = both maps of the own scope only
      (uniform shadowing — outer names of either kind may be shadowed)
- [x] Call expression: chain-walk lookup; undefined function → runtime
      error; argument-count mismatch → runtime error; fresh child env with
      params bound to evaluated args, **parent = found-env** (NOT the
      caller's env). Free the call env when the call ends.
- [x] `return`: mechanism to stop mid-body and carry the value out. Two
      candidates — a `RETURN` signal fault + return-value side channel
      (mirrors the `Error` side channel), or a `{bool returned; float value}`
      result threaded through block/statement eval. Weigh both before
      coding.
- [x] Missing-return enforcement (static pass vs runtime, per the decision
      above)
- [x] Recursion: works via chain lookup (covers local-fn recursion too).
      Add a call-depth limit → clean runtime error instead of stack
      overflow.
- [x] Lifetime/ownership: `functions` entries are **non-owning**; env
      teardown never frees declaration ASTs. Local fns: their Statement is
      owned by the enclosing body, which outlives the call env — nothing
      to do. Top-level fns: owned by the program/REPL line — file mode is
      fine (program freed after the run), but the REPL frees each line
      after eval and must keep fn-declaration lines (buffer + AST) alive.
- [x] End-to-end tests (in `tests/functions_test.c3`; recursion tests
      deferred — without control flow a recursive call cannot terminate):
      - basics: simple call, call inside expressions, multiple params,
        recursion
      - scoping: body reads a global; param/local shadows a global (global
        unchanged after the call); body `x = ...` mutates a global;
        lexical-not-dynamic (`fn helper(){return x}` called from `work()`
        that has `var x` → undefined reference)
      - local fns: declare + call inside a body; not visible after the
        enclosing call ends; local recursion
      - shadowing: local `var f` shadows outer `fn f` (and `f` is callable
        again after the scope ends)
      - errors: same-scope collision, arg-count mismatch, undefined
        function, missing return (incl. nested-fn case)

## Later milestone: resolver (semantic pass) — the road to compiling

Decision: functions ship with **runtime checks** (simplest, REPL-friendly).
But the long-term goal is **compilation**, so a resolver pass is planned as
its own milestone after functions. It is additive — a second walk over the
unchanged AST between parse and eval; the evaluator only loses checks. The
tree-walking evaluator stays as the reference implementation (and the REPL
stays interpreted even once file mode compiles).

- [ ] First check: missing `return` (per the open static-vs-runtime lean)
- [ ] Then migrate name/arity checks: undefined reference, same-scope
      collision, call arity — a scope stack of name/kind/arity, no values
- [ ] Decide declaration visibility at that point: declaration-before-use
      vs hoisting fn names (hoisting ⇒ order-independent mutual
      recursion). Today declarations are statements that execute — the one
      semantic that CANNOT survive compilation unchanged; expect some
      programs to change meaning, rely on the test suite to see it.
- [ ] Eventually: resolver annotates identifiers with (depth, slot) →
      codegen replaces hashmap lookups with frame offsets
- Guardrails until then: add no features whose name-resolution depends on
  runtime values (dynamic names, eval-like constructs); keep error-behavior
  tests growing — they are the executable spec for later semantic shifts.

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
