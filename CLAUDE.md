# calc-comp

A calculator compiler written in **C3** (https://c3-lang.org). Currently at the
interpreter stage: lexer → recursive-descent parser → AST → tree-walking
evaluator. Supports math expressions with `+ - * /`, parentheses, and decimal
numbers.

## IMPORTANT: This is a learning project

The author (Dalibor) treats this project primarily as a **learning experience**.
Unless explicitly asked otherwise:

- **Do not generate implementation code for new features.** Explain concepts,
  approaches, and trade-offs instead; let the author write the code.
- Reviewing code the author wrote, answering questions, and writing tests when
  asked is fine.

## Build & test

C3 project driven by `project.json` (target: `calc_comp`, executable).

```
c3c build        # build
c3c test         # run tests in tests/
```

- There is currently **no `main`** in `src/` — the tests are the only driver.
- `build/` is generated output; ignore it.

## Layout

- `src/lexer.c3` — `Token`, `TokenType`, `Lexer` (char-by-char, `read_position`
  / `current_char` style)
- `src/parser.c3` — AST (`Expression` tagged union: `NUMBER`, `BINARY`) and
  `Parser`. Precedence is encoded in the call chain:
  `parse_expression` (+/-) → `parse_term` (*//) → `parse_factor` (number, parens)
- `src/util.c3` — `exit()`, `char.is_number()`, `read_file()`,
  `print_expression()`, `free_expression()`, `eval()` / `eval_binary()`
- `tests/calc_test.c3` — lexer, parser-shape, and end-to-end eval tests
  (helpers: `parse_source`, `eval_source`, `assert_eval`)

Everything lives in a single module: `module calc_comp;`.

## Language design decisions (agreed with the author)

- **Every value is a float.** No type system, no other types for now.
- **No semicolons.** A newline ends a statement (this will matter for the
  planned REPL).
- Variable declaration syntax: `var x = <expression>`
- **Redeclaring a variable is an error** (`var x = 1` then `var x = 2` → error).
- **Assignment without `var` is an error** — `x = 5` is not valid; there is no
  plain assignment statement (may be added as a separate feature later).
- Referencing an undefined variable is a runtime error.
- Error handling style so far: print a message and `exit()` — no error
  recovery/propagation yet.

## Roadmap

See `TODO.md` for the current checklist. Broad order: variables → simple REPL.

## Code conventions

- Tabs for indentation in `src/`, C3 "method" syntax
  (`fn void Lexer.init(Lexer* this, ...)`).
- AST nodes are tagged unions: a `kind` enum + `union` of variant structs.
- AST nodes are heap-allocated with `mem::new` and freed recursively with
  `free_expression`.
- Gotcha: `Token.value` is a **slice into the source buffer**, not a copy. If a
  string must outlive the source (e.g. variable names stored in an environment
  once the REPL reuses line buffers), it must be copied.
