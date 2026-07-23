# TODO — Milestone 1: types (bool + annotations) → Milestone 2: control flow

Order agreed: types first, control flow second — `if`/`while` conditions
will REQUIRE a bool, so the type must exist before the syntax.

```
var x: float = 5
fn equals(x: float, y: float): bool {
    return x == y
}

var i = 0
while (i < 10) {
    i = i + 1
}
if (i > 0) {
    i = 0
} else {
    i = 1
}
```

## Resolved this round

- **No truthiness.** Conditions must evaluate to a bool; a float in a
  condition is a runtime error. Comparisons yield bool (superseded the
  "1.0/0.0" idea).
- **Comparison operators** `< > <= >= == !=` bind *looser* than `+ -`
  (new top level in the parse chain). First two-char tokens — lexer needs
  one char of lookahead.
- **Operator enum** replaces `BinaryExpression.operator: char`.
- **`else` is in scope** for the control-flow milestone.
- **Block scoping:** if/while/else bodies run in a child env; `while`
  creates a **fresh child env per iteration**.
- **Missing-return rule stays conservative:** parser keeps requiring the
  last body statement to be `return`, even when an if/else before it
  returns on every path. Proper reachability analysis is resolver work.
- **`break` and `continue` are in scope** for the control-flow milestone
  (loop-only; parser enforces placement structurally, like `allow_return`).

- **Bool rules:** `true`/`false` keyword literals; bools are
  **first-class values** (storable in vars, passable as params,
  returnable — variables stay untyped cells, values carry the type);
  `==`/`!=` work on two operands of the SAME type, mixed-type equality
  is a runtime error; arithmetic and ordering comparisons
  (`+ - * / < <= > >=`) require floats — bool operands are a runtime
  error; REPL prints `true`/`false`.
- **Propagation mechanism: completion record** (chosen over signal
  faults — faults stay errors-only). Statement/block eval returns
  `{NORMAL | RETURNED(value) | BROKE | CONTINUED}`; every construct
  routes its children's record: blocks stop early and pass it up, loops
  intercept BROKE (exit → NORMAL) and CONTINUED (next iteration), the
  call boundary intercepts RETURNED and takes the value; non-NORMAL at
  top level is a bug the parser should have prevented.
- **Static typing via annotations** (`var x: float = 5`,
  `fn equals(x: float, y: float): bool`). The language is statically
  typed by declaration; `float`/`bool`/`void` become reserved keywords.
  **Annotations are mandatory everywhere** — `var`, every param, the
  return type; no inference. (Breaks all existing unannotated
  programs/tests — accepted; updating them is part of Milestone 1.)
  Enforcement is at **runtime for now** (checked at var init, assignment,
  argument binding, and return — same runtime-check model as names) and
  becomes a true compile-time check in the resolver, which annotations
  make straightforward: every expression's type derives bottom-up.
  Assignment must match the variable's declared type.
- **`void` return type** (revised — replaces "no void functions").
  `void` is legal ONLY as a return type, never on a var or param. A void
  fn does not require a `return`; bare `return` (no expression) is
  allowed for early exit; `return <expr>` in a void fn is an error, as
  is a valueless `return` in a non-void fn. Using a void call where a
  value is needed (var init, operand, argument, condition, assignment
  rhs, non-void return) is a runtime error; a void call as an expression
  statement is fine and prints nothing. The missing-return parser rule
  now applies to non-void fns only. The completion record's RETURNED
  may carry no value.

## Milestone 1: types (bool + annotations)

- [x] `Type` enum (`FLOAT`, `BOOL`, `VOID`) — doubles as the `Value` kind
      tag and the representation of annotations in the AST (`VOID` legal
      in return position only)
- [x] `Value` tagged union `{ type, float | bool }` replaces bare `float`
      in eval results, env `variables` map, params/returns
- [x] Lexer: `true`/`false`, `float`/`bool`/`void` keywords; `COLON`
      token
- [x] AST: bool literal expression kind; type field on
      `VarDeclarationStatement`; fn params become `{name, type}` pairs
      (small Param struct beats parallel lists); return type on
      `FnDeclarationStatement`; `ReturnStatement.expression` may be null
      (bare `return`)
- [x] Parser: mandatory `: type` after var name and each param, `: type`
      after the param list `)`; reject `void` on vars/params; bare
      `return` (newline/`}` after `return`); missing-return rule only
      for non-void fns; type-keyword error messages
- [x] Eval type rules per the resolved bool rules above; annotation
      checks at var init, assignment, argument binding, and return;
      void-value-used-where-value-needed errors
      (`RUNTIME_ERROR` + message, as usual)
- [x] REPL/expression-statement printing: bools as `true`/`false`; void
      call results print nothing
- [x] Update ALL existing tests + helpers to annotated syntax (mandatory
      annotations break them by design)
- [x] Tests: literals, annotation syntax shapes, void fns (no return,
      bare return, `return <expr>` error, void-in-value-position
      errors), storing/passing/returning bools, each type-error case
      (init, assign, arg, return, bool arithmetic; mixed equality waits
      for `==` in milestone 2), printing

## Milestone 2: control flow (after 1)

- [ ] Lexer: `if`/`else`/`while`/`break`/`continue` keywords; comparison
      tokens with one-char lookahead; token tests
- [ ] AST: operator enum rework; `IfStatement` (condition, then-block,
      optional else-block), `WhileStatement` (condition, body), `BREAK`,
      `CONTINUE`
- [ ] Parser: `parse_comparison` level above `parse_expression`; `IF`
      (with optional `else`) and `WHILE` arms (parens required around
      conditions, bodies via `parse_block`), legal at top level and in
      bodies; thread `allow_return` AND a new loop flag for
      `break`/`continue` into nested blocks (an if inside a loop inherits
      both; a fn body resets the loop flag); free_* for new kinds;
      shape + error-path tests (misplaced break/continue/return included)
- [ ] Eval: condition must be bool; if/else; while with per-iteration
      child env; the completion record (call boundary catches RETURNED,
      loop catches BROKE/CONTINUED); e2e tests: counting loop,
      early return from inside a loop, break/continue behavior, nested
      loops, else branch, condition type errors
- [ ] Recursion: now terminable — recursion tests + call-depth limit
      (clean runtime error instead of stack overflow)

## Later

- [ ] `for` loops — desugar-to-while vs first-class node. NOTE: if
      `continue` exists, desugaring is the tricky option (`continue` must
      still run the step expression). Decide when close.
- [ ] Logical operators `&&`, `||`, `!` (natural fit once bool exists)
- [ ] Resolver / semantic pass — road to compiling; missing-return
      reachability, name/arity checks, and full static type checking
      (bottom-up over annotations) migrate there; once types are checked
      statically, compiled code needs no runtime type tags (`Value`
      becomes interpreter-only)

## Leftovers

- [ ] REPL: multi-line declarations unsupported (one statement per line;
      brace accumulation deferred) — will bite harder once `while` bodies
      want multiple lines
- [ ] REPL: parse/eval error paths leak the line buffer
- [ ] Expression statements don't enforce a NEW_LINE/EOF terminator
      (`1 2` parses as two statements)
- [ ] Error-reporting split: parser errors use the `Error` side channel;
      runtime errors print directly from `eval.c3`
- [ ] File mode truncates input over the fixed 2048-byte `read_file`
      buffer
