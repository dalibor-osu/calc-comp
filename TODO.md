# TODO: Variables

Goal: `var x = <expression>`, newline ends a statement, everything is a float.
Redeclaration is an error, assignment without `var` is an error.

## Lexer

- [x] Add token types: `IDENT`, `VAR`, `ASSIGN` (`=`), `NEWLINE`
- [x] `read_identifier` (letters/underscore), analogous to `read_number`
- [x] Keyword lookup: lex letters as identifier, then check text — `"var"` →
      `VAR`, otherwise `IDENT`
- [x] Make `\n` significant: stop skipping it in `skip_whitespace`, emit a
      `NEWLINE` token instead (keep skipping `\r` for Windows line endings)
- [x] Update existing lexer tests that assume `\n` is skipped whitespace
      (e.g. `lexer_skips_whitespace`); add tests for the new tokens

## AST + Parser

- [x] New `Statement` node (tagged union, same pattern as `Expression`):
      - var declaration: name + initializer expression
      - expression statement: bare expression (needed for the REPL)
- [x] New `Expression` kind: identifier (variable reference, holds the name)
      — handled in `parse_factor` next to `NUMBER`
- [x] `parse_statement`: on `VAR` → expect `IDENT`, `ASSIGN`, expression;
      otherwise parse an expression statement. Statement ends at
      `NEWLINE`/`EOF`
- [x] `parse_program`: loop statements until `EOF`, skipping blank lines
- [x] Update `free_expression` for the new node kinds
  - Added free_program
- [x] Parser-shape tests for var declaration and identifier reference

## Evaluation

- [x] Environment: hash map name → float (`std::collections::map`), passed as
      a pointer through the eval functions
- [x] Var statement: evaluate right side, store under the name
      - error if the name already exists (redeclaration)
      - copy the name string when storing (token values are slices into the
        source buffer)
- [x] Identifier expression: look up in environment; error if undefined
- [x] Bare `x = 5` (no `var`): error
- [x] Expression statement: evaluate and print the result
- [x] End-to-end tests: declare + use, redeclaration error, undefined variable
      error

## Later

- [x] Simple REPL (line by line — newline-terminated statements come in handy)
- [x] Plain assignment to existing variables (`x = 5`) as a separate feature
