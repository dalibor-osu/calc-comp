# calc-comp

A calculator compiler written in **C3** (https://c3-lang.org), built with
c3c 0.8.3 (pre-release). Currently at the interpreter stage: lexer →
recursive-descent parser → AST → tree-walking evaluator, with two front
ends: a file runner and a REPL. Supports math expressions (`+ - * /`,
parentheses, decimals) and variables (`var x = ...`, `x = ...`). The next
milestone is **functions** — see `TODO.md`.

## IMPORTANT: This is a learning project

The author (Dalibor) treats this project primarily as a **learning
experience**. Unless explicitly asked otherwise:

- **Do not generate implementation code for new features.** Explain concepts,
  approaches, and trade-offs instead; let the author write the code.
- Reviewing code the author wrote, answering questions, and writing tests
  when asked is fine.
- Established convention: when a review finds a real bug in `src/`, add a
  test that exposes it, report precisely where and why, and leave the fix to
  the author. Red tests are welcome as work items.

## Build & test

C3 project driven by `project.json` (target `calc_comp`, executable).

```
c3c build                    # build → ./build/calc_comp
c3c test                     # run tests in tests/
./build/calc_comp input.txt  # evaluate a file
./build/calc_comp            # no args → REPL ("|>" prompt, Ctrl-D exits)
```

- `build/` is generated output; ignore it.
- The test runner wraps every `@test` in a **tracking allocator and fails
  the test on leaked heap memory**. This is used deliberately: the
  error-path tests double as leak tests for the parser's `defer catch`
  cleanup.

## Layout

Everything lives in a single module: `module calc_comp;`.

- `src/lexer.c3` — `TokenType`, `Token`, `Lexer` (`init`, `next`, `peek`,
  `read_number`, `read_identifier`, keyword lookup via `lookup_keyword`).
  Char-by-char with `read_position`/`current_char`. `\n` is a `NEW_LINE`
  token (statements end at newlines); `\r`, space, tab are skipped.
- `src/ast.c3` — tagged-union AST nodes (a `kind` enum + `union` of variant
  structs). `Expression`: `NUMBER`, `BINARY`, `IDENTIFIER`. `Statement`:
  `VAR_DECLARATION`, `VAR_ASSIGN`, `EXPRESSION`.
- `src/parser.c3` — `alias Program = List{Statement*}`, `Parser`
  (`init`/`advance`/`expect`/`expect_any`, one-token lookahead in
  `current`). Precedence is encoded in the call chain: `parse_expression`
  (+/-) → `parse_term` (*, /) → `parse_factor` (number, identifier,
  parens). `parse_statement` disambiguates assignment (`x = ...`) from an
  expression statement via `lexer.peek()`.
- `src/eval.c3` — `alias Environment = HashMap{String, float}`,
  `eval_expression` / `eval_binary` / `eval_statement` / `eval_program`.
- `src/util.c3` — `faultdef LEXER_ERROR, PARSER_ERROR, RUNTIME_ERROR`,
  `struct Error { String message; }`, char classifier methods,
  `read_file`, `free_expression` / `free_statement` / `free_program`.
- `src/main.c3` — `main` (file mode) and `run_repl` (one statement per
  line, `@pool()` + `io::treadline()` per iteration, prints parse errors,
  frees each line's statement, exits on `io::EOF`).
- `tests/calc_test.c3` — lexer, parser-shape, parse-error, and end-to-end
  eval tests. Helpers: `parse_source` (single expression), `eval_source`
  (runs a whole program, returns the last expression statement's value
  without printing), `assert_eval`, `assert_runtime_error`,
  `assert_parse_error(source, expected_message, fault = PARSER_ERROR)`.

## Language design decisions (agreed with the author)

- **Every value is a float.** No other types, no void.
- **No semicolons.** A newline ends a statement.
- `var x = <expression>` declares; **redeclaring is a runtime error**.
- `x = <expression>` (no `var`) assigns; **only valid if `x` already
  exists**, otherwise runtime error. Parsed as a distinct `VAR_ASSIGN`
  statement.
- Referencing an undefined variable is a runtime error.
- **Division by zero is a runtime error** (not infinity).
- Next milestone, functions (syntax agreed):

  ```
  fn foo(bar, baz) {
      return bar + baz
  }
  ```

  All parameters and return values are floats; no void functions. Resolved
  design decisions:
  - **Isolated scope** — a body sees only its parameters and its own `var`
    locals, never global variables (pass data in as parameters). Each call
    runs in a fresh Environment. Subtlety: "no globals" means no global
    *variables*; the **function table is still global**, so recursion and
    mutual calls work.
  - **Separate namespace, no overlap** — a function and a variable cannot
    share a name; declarations check both the variable env and the function
    table.
  - **Missing `return` is an error** — static detection preferred (would be
    the first semantic pass; easy while there's no control flow), runtime
    detection is the fallback. See `TODO.md`.
  - **No nested functions** — `fn` is top-level only, `return` is body-only.
    Enforced structurally by separate parser entry points: `parse_program`
    (accepts `fn`, not `return`) vs `parse_block` for bodies (accepts
    `return`, not `fn`).
  - **No brace/newline formatting rules** — `{`/`}` may sit anywhere; block
    parsing skips newlines liberally.
  - **REPL accumulates lines until braces balance** before parsing a
    multi-line function. This changes the per-line lifetime: the accumulated
    buffer and any stored function AST must outlive a single REPL line
    (today each line's statement is freed right after eval).

## Error handling architecture

- Fallible functions return optionals (`Token?`, `void?`, `Expression*?`,
  `Program?`, `float?`) and propagate with `!`; the faults are
  `LEXER_ERROR` / `PARSER_ERROR` / `RUNTIME_ERROR`.
- C3 faults carry no payload, so messages travel **out of band** in
  `Lexer.error` / `Parser.error` (`Error` struct). `Parser.advance` copies
  `lexer.error` → `parser.error` on lexer faults; any *direct* lexer call
  from the parser (e.g. `peek` in `parse_statement`) must do the same —
  forgetting this once caused empty error messages.
- Lower layers are silent; `main`/REPL catch at the top and print
  `parser.error.message`. **Known inconsistency** (tracked in TODO):
  runtime errors print directly inside `eval.c3` and the REPL's eval
  `catch` is deliberately empty.
- **AST ownership rule:** each parse function owns what it allocated until
  successful hand-off to its caller; every fault exit frees via
  `defer catch`. Current placements: `parse_program` (pushed statements +
  list), `parse_statement` (raw `Statement`, and `rhs` between parse and
  attachment), `parse_expression`/`parse_term` (accumulated `left`),
  `parse_factor` (fresh node / paren subtree). Extend the same pattern to
  new node kinds; the leak-detecting tests enforce it.

## C3 gotchas learned on this project

- `Token.value` and identifier names are **slices into the source buffer**,
  not copies. BUT: `HashMap` with `String` keys **copies keys itself** on
  `set` and frees them in `free()` (`COPY_KEYS` in the stdlib) — do NOT
  `.copy()` manually when storing env entries; that caused a leak once.
- **No static methods** in c3c 0.8.3 — a method's first parameter must be
  the receiver (`Type` or `Type*`). "Constructors" are in-place init
  methods: `fn void Type.init(Type* this, ...)`.
- The compiler rejects `assert(false, ...)` — use `unreachable("msg")`.
- `defer catch` runs only when the scope exits via a fault (twin:
  `defer try`) — this is the parser's cleanup mechanism.
- `std::collections::result` exists, but its own docs recommend optionals +
  faults unless the error needs structured payload; this project uses
  optionals + the `Error` side channel instead (Result was tried and
  rolled back).
- `io::treadline()` / `io::readline()` fault with `io::EOF` on Ctrl-D —
  don't confuse with `TokenType.EOF`.
- Test functions are `fn void name() @test` in `test-sources`
  (`project.json`); run with `c3c test`.

## Code conventions

- Tabs for indentation in older `src/` code, spaces in newer parts — match
  the surrounding code.
- AST nodes are heap-allocated with `mem::new` and freed recursively with
  `free_expression` / `free_statement` / `free_program`.
