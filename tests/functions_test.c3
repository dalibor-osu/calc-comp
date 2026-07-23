module calc_comp;

// --- Functions: parsing ---

fn void parser_fn_declaration_shape() @test {
    Lexer lexer;
    lexer.init("fn add(a: float, b: bool): float {\nreturn a\n}");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    assert(program.len() == 1);
    Statement* statement = program[0];
    assert(statement.kind == StatementKind.FN_DECLARATION);
    assert(statement.fn_dec.name == "add");
    assert(statement.fn_dec.parameter_count == 2);
    assert(statement.fn_dec.parameters[0].name == "a");
    assert(statement.fn_dec.parameters[0].type == Type.FLOAT);
    assert(statement.fn_dec.parameters[1].name == "b");
    assert(statement.fn_dec.parameters[1].type == Type.BOOL);
    assert(statement.fn_dec.return_type == Type.FLOAT);
    assert(statement.fn_dec.body.len() == 1);
    assert(statement.fn_dec.body[0].kind == StatementKind.RETURN);
}

fn void parser_fn_no_params_shape() @test {
    Lexer lexer;
    lexer.init("fn one(): float {\nreturn 1\n}");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    assert(program.len() == 1);
    Statement* statement = program[0];
    assert(statement.kind == StatementKind.FN_DECLARATION);
    assert(statement.fn_dec.parameter_count == 0);
    assert(statement.fn_dec.return_type == Type.FLOAT);
    assert(statement.fn_dec.body.len() == 1);
}

fn void parser_fn_void_needs_no_return() @test {
    // A void fn's body does not have to end with return
    Lexer lexer;
    lexer.init("fn setup(): void {\nvar x: float = 1\n}");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    Statement* statement = program[0];
    assert(statement.kind == StatementKind.FN_DECLARATION);
    assert(statement.fn_dec.return_type == Type.VOID);
    assert(statement.fn_dec.body.len() == 1);
}

fn void parser_bare_return_shape() @test {
    // Bare return: expression pointer is null
    Lexer lexer;
    lexer.init("fn quit(): void {\nreturn\n}");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    Statement* statement = program[0];
    assert(statement.fn_dec.body.len() == 1);
    assert(statement.fn_dec.body[0].kind == StatementKind.RETURN);
    assert(statement.fn_dec.body[0].ret.expression == null);
}

fn void parser_fn_body_multiple_statements() @test {
    Lexer lexer;
    lexer.init("fn f(x: float): float {\nvar y: float = x + 1\nreturn y\n}");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    Statement* statement = program[0];
    assert(statement.kind == StatementKind.FN_DECLARATION);
    assert(statement.fn_dec.body.len() == 2);
    assert(statement.fn_dec.body[0].kind == StatementKind.VAR_DECLARATION);
    assert(statement.fn_dec.body[1].kind == StatementKind.RETURN);
}

fn void parser_fn_brace_may_sit_anywhere() @test {
    // Agreed rule: no brace/newline formatting restrictions
    Lexer lexer;
    lexer.init("fn one(x: float): float\n{\nreturn x\n}");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    assert(program.len() == 1);
    assert(program[0].kind == StatementKind.FN_DECLARATION);
}

fn void parser_local_fn_shape() @test {
    // Local functions: fn inside a body must parse
    Lexer lexer;
    lexer.init("fn outer(x: float): float {\nfn inner(y: float): float {\nreturn y\n}\nreturn inner(x)\n}");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    assert(program.len() == 1);
    Statement* outer = program[0];
    assert(outer.kind == StatementKind.FN_DECLARATION);
    assert(outer.fn_dec.body.len() == 2);
    assert(outer.fn_dec.body[0].kind == StatementKind.FN_DECLARATION);
    assert(outer.fn_dec.body[0].fn_dec.name == "inner");
    assert(outer.fn_dec.body[1].kind == StatementKind.RETURN);
}

fn void parser_call_no_args() @test {
    Lexer lexer;
    lexer.init("one()");
    Parser parser;
    parser.init(&lexer)!!;
    Expression* exp = parser.parse_expression()!!;
    defer free_expression(exp);

    assert(exp.kind == ExpressionKind.CALL);
    assert(exp.call.name == "one");
    assert(exp.call.parameter_count == 0);
    // the call must consume its entire token stream, including ')'
    assert(parser.current.type == TokenType.EOF, "call must consume its closing paren");
}

fn void parser_call_one_arg() @test {
    Lexer lexer;
    Expression* exp = parse_source("sq(1 + 2)", &lexer);
    defer free_expression(exp);

    assert(exp.kind == ExpressionKind.CALL);
    assert(exp.call.name == "sq");
    assert(exp.call.parameter_count == 1);
    assert(exp.call.parameters[0].kind == ExpressionKind.BINARY);
}

fn void parser_call_two_args() @test {
    Lexer lexer;
    lexer.init("add(1, true)");
    Parser parser;
    parser.init(&lexer)!!;
    Expression* exp = parser.parse_expression()!!;
    defer free_expression(exp);

    assert(exp.kind == ExpressionKind.CALL);
    assert(exp.call.parameter_count == 2);
    assert(exp.call.parameters[0].kind == ExpressionKind.NUMBER);
    assert(exp.call.parameters[1].kind == ExpressionKind.BOOL);
}

fn void parser_call_inside_expression() @test {
    Lexer lexer;
    Expression* exp = parse_source("2 * sq(3)", &lexer);
    defer free_expression(exp);

    assert(exp.kind == ExpressionKind.BINARY);
    assert(exp.bin.operator == '*');
    assert(exp.bin.right.kind == ExpressionKind.CALL);
}

fn void parser_error_top_level_return() @test {
    assert_parse_error("return 1", "Unexpected return statement encountered");
}

fn void parser_error_fn_missing_name() @test {
    assert_parse_error("fn (): float {\nreturn 1\n}", "missing or invalid function name");
}

fn void parser_error_fn_missing_return_type() @test {
    // Return annotation is mandatory
    assert_parse_error("fn f() {\nreturn 1\n}", "missing type annotation in fn declaration (fn <name>(<args>): <return_type> { <body> })");
}

fn void parser_error_param_missing_annotation() @test {
    // Param annotations are mandatory
    assert_parse_error("fn f(x): float {\nreturn x\n}", "variable identifier must be followed by type annotation (var <name>: <type> = <value>)");
}

fn void parser_error_param_void_type() @test {
    // void is a return type only
    assert_parse_error("fn f(x: void): float {\nreturn 1\n}", "invalid variable type");
}

fn void parser_error_void_fn_returning_value() @test {
    assert_parse_error("fn f(): void {\nreturn 1\n}", "invalid return statement; void fn can't return a value");
}

fn void parser_error_fn_missing_return() @test {
    assert_parse_error("fn f(): float {\nvar x: float = 1\n}", "Missing return statement");
}

fn void parser_error_fn_empty_body() @test {
    assert_parse_error("fn f(): float {\n}", "Missing return statement");
}

fn void parser_error_unclosed_block() @test {
    assert_parse_error("fn f(): float {\nreturn 1", "Block not ended");
}

fn void parser_error_missing_param_name() @test {
    assert_parse_error("fn f(a: float,): float {\nreturn a\n}", "missing parameter name after comma");
}

fn void parser_error_call_argument_cleanup() @test {
    // The already-parsed argument must be freed when the call errors out
    assert_parse_error("sq(1 2", "invalid fn call");
}

fn void parser_error_fn_body_cleanup() @test {
    // Body statements already parsed must be freed when a later
    // body statement fails
    assert_parse_error("fn f(): float {\nvar x: float = 1\n(2\n}", "Missing closing parentheses");
}

// --- Functions: evaluation ---

fn void eval_fn_call_one_param() @test {
    assert_eval("fn sq(x: float): float {\nreturn x * x\n}\nsq(3)", 9.0);
}

fn void eval_fn_call_no_params() @test {
    assert_eval("fn one(): float {\nreturn 1\n}\none()", 1.0);
}

fn void eval_fn_call_two_params() @test {
    assert_eval("fn add(a: float, b: float): float {\nreturn a + b\n}\nadd(1, 2)", 3.0);
}

fn void eval_fn_call_in_expression() @test {
    assert_eval("fn sq(x: float): float {\nreturn x * x\n}\nsq(2) + sq(3)", 13.0);
}

fn void eval_fn_nested_call() @test {
    assert_eval("fn sq(x: float): float {\nreturn x * x\n}\nsq(sq(2))", 16.0);
}

fn void eval_fn_multi_statement_body() @test {
    assert_eval("fn f(x: float): float {\nvar y: float = x + 1\nreturn y * 2\n}\nf(3)", 8.0);
}

fn void eval_fn_var_initialized_from_call() @test {
    assert_eval("fn inc(x: float): float {\nreturn x + 1\n}\nvar y: float = inc(4)\ny", 5.0);
}

fn void eval_fn_bool_param_and_return() @test {
    assert_eval_bool("fn nay(b: bool): bool {\nreturn b\n}\nnay(false)", false);
}

fn void eval_fn_bool_result_into_var() @test {
    assert_eval_bool("fn yes(): bool {\nreturn true\n}\nvar b: bool = yes()\nb", true);
}

// --- Functions: void ---

fn void eval_void_fn_call() @test {
    // A void fn runs to the end of its body without needing a return
    assert_eval_void("fn setup(): void {\nvar x: float = 1\n}\nsetup()");
}

fn void eval_void_fn_bare_return() @test {
    // Bare return exits a void fn early
    assert_eval_void("fn quit(): void {\nreturn\n}\nquit()");
}

fn void parser_error_bare_return_in_nonvoid_fn() @test {
    // A valueless return in a non-void fn is an error (author's chosen
    // mechanism: parse time, via the all-returns scan)
    assert_parse_error("fn f(): float {\nreturn\n}", "invalid return statement; fn with return type can't return void");
}

fn void eval_error_void_call_in_value_position() @test {
    // A void call produces no value: using it as one is an error
    assert_runtime_error("fn setup(): void {\nvar x: float = 1\n}\nvar y: float = setup()");
}

// --- Functions: type errors ---

fn void eval_error_arg_type_mismatch() @test {
    // Argument binding must respect the param annotation
    assert_runtime_error("fn id(x: float): float {\nreturn x\n}\nid(true)");
}

fn void eval_error_arg_type_mismatch_bool_param() @test {
    assert_runtime_error("fn id(b: bool): bool {\nreturn b\n}\nid(1)");
}

fn void eval_error_return_type_mismatch() @test {
    // The returned value must match the declared return type
    assert_runtime_error("fn f(): bool {\nreturn 1\n}\nf()");
}

fn void eval_error_return_type_mismatch_float() @test {
    assert_runtime_error("fn f(): float {\nreturn true\n}\nf()");
}

// --- Functions: scoping ---

fn void eval_fn_body_reads_global() @test {
    assert_eval("var g: float = 10\nfn f(x: float): float {\nreturn x + g\n}\nf(1)", 11.0);
}

fn void eval_fn_param_shadows_global() @test {
    assert_eval("var x: float = 1\nfn f(x: float): float {\nreturn x * 10\n}\nf(5)", 50.0);
}

fn void eval_fn_shadowing_leaves_global_untouched() @test {
    // Writing to the shadowing param must not touch the global
    assert_eval("var x: float = 1\nfn f(x: float): float {\nx = 99\nreturn x\n}\nf(5)\nx", 1.0);
}

fn void eval_fn_local_var_shadows_global() @test {
    assert_eval("var x: float = 1\nfn f(y: float): float {\nvar x: float = 9\nreturn x + y\n}\nf(1)", 10.0);
}

fn void eval_fn_assign_to_global_mutates_it() @test {
    // Agreed rule: assignment to a global from inside a body is legal
    assert_eval("var x: float = 1\nfn f(y: float): float {\nx = y\nreturn 0\n}\nf(42)\nx", 42.0);
}

fn void eval_fn_lexical_scoping_not_dynamic() @test {
    // helper's body must resolve names against ITS definition scope,
    // not its caller's: work's local x must be invisible inside helper
    assert_runtime_error("fn helper(a: float): float {\nreturn x + a\n}\nfn work(a: float): float {\nvar x: float = 5\nreturn helper(a)\n}\nwork(1)");
}

fn void eval_error_undefined_in_body() @test {
    assert_runtime_error("fn f(x: float): float {\nreturn x + zzz\n}\nf(1)");
}

// --- Functions: local functions ---

fn void eval_local_fn() @test {
    assert_eval("fn outer(x: float): float {\nfn inner(y: float): float {\nreturn y * 2\n}\nreturn inner(x) + 1\n}\nouter(3)", 7.0);
}

fn void eval_local_fn_not_visible_after_call() @test {
    assert_runtime_error("fn outer(x: float): float {\nfn inner(y: float): float {\nreturn y\n}\nreturn inner(x)\n}\nouter(1)\ninner(1)");
}

// --- Functions: namespaces & shadowing across kinds ---

fn void eval_local_var_shadows_outer_fn() @test {
    // Agreed rule: uniform shadowing — a local var may shadow an outer fn
    assert_eval("fn f(x: float): float {\nreturn x\n}\nfn g(x: float): float {\nvar f: float = 2\nreturn f + x\n}\ng(1)", 3.0);
}

fn void eval_calling_shadowed_fn_is_an_error() @test {
    // Inside g, the name f is the local variable, not the outer fn
    assert_runtime_error("fn f(x: float): float {\nreturn x\n}\nfn g(x: float): float {\nvar f: float = 2\nreturn f(x)\n}\ng(1)");
}

fn void eval_fn_usable_after_shadowing_scope_ends() @test {
    assert_eval("fn f(x: float): float {\nreturn x\n}\nfn g(x: float): float {\nvar f: float = 2\nreturn f + x\n}\ng(1)\nf(7)", 7.0);
}

// --- Functions: runtime errors ---

fn void eval_error_arity_mismatch() @test {
    assert_runtime_error("fn add(a: float, b: float): float {\nreturn a + b\n}\nadd(1)");
}

fn void eval_error_undefined_function() @test {
    assert_runtime_error("foo(1)");
}

fn void eval_error_fn_redeclaration() @test {
    assert_runtime_error("fn f(x: float): float {\nreturn x\n}\nfn f(x: float): float {\nreturn x\n}");
}

fn void eval_error_var_then_fn_collision() @test {
    assert_runtime_error("var f: float = 1\nfn f(x: float): float {\nreturn x\n}");
}

fn void eval_error_fn_then_var_collision() @test {
    assert_runtime_error("fn f(x: float): float {\nreturn x\n}\nvar f: float = 1");
}

fn void eval_error_calling_a_variable() @test {
    assert_runtime_error("var x: float = 1\nx(2)");
}

fn void eval_error_fn_used_as_variable() @test {
    assert_runtime_error("fn f(x: float): float {\nreturn x\n}\nf + 1");
}

fn void eval_error_assigning_to_fn() @test {
    assert_runtime_error("fn f(x: float): float {\nreturn x\n}\nf = 3");
}
