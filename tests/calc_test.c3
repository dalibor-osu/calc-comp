module calc_comp;
import std::math;

// AI generated test lolololololololo

fn Expression* parse_source(String source, Lexer* lexer) {
    lexer.init(source);
    Parser parser;
    parser.init(lexer)!!;
    return parser.parse_expression()!!;
}

// Evaluates a whole program and returns the value of the last expression
// statement (without printing it).
fn float eval_source(String source) {
    Lexer lexer;
    lexer.init(source);
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    Environment env;
    env.init(mem);
    defer env.free();

    float result = 0;
    foreach (statement : program) {
        switch (statement.kind) {
            case VAR_DECLARATION:
            case VAR_ASSIGN:
                eval_statement(statement, &env)!!;
            case EXPRESSION:
                result = eval_expression(statement.exp.expression, &env)!!;
        }
    }
    return result;
}

fn void assert_eval(String source, float expected) {
    float result = eval_source(source);
    assert(math::abs(result - expected) < 0.0001, "wrong result for expression");
}

fn void assert_runtime_error(String source) {
    Lexer lexer;
    lexer.init(source);
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    Environment env;
    env.init(mem);
    defer env.free();

    foreach (statement : program) {
        if (catch excuse = eval_statement(statement, &env)) {
            assert(excuse == RUNTIME_ERROR);
            return;
        }
    }
    unreachable("expected a runtime error");
}

fn void assert_parse_error(String source, String expected_message, fault expected_fault = PARSER_ERROR) {
    Lexer lexer;
    lexer.init(source);
    Parser parser;
    parser.init(&lexer)!!;
    Program? program = parser.parse_program();
    if (catch excuse = program) {
        assert(excuse == expected_fault);
        assert(parser.error.message == expected_message, "unexpected parser error message");
        return;
    }
    unreachable("expected a parse error");
}

// --- Lexer ---

fn void lexer_single_char_tokens() @test {
    Lexer lexer;
    lexer.init("( ) + - * / =");
    assert(lexer.next()!!.type == TokenType.L_PAREN);
    assert(lexer.next()!!.type == TokenType.R_PAREN);
    assert(lexer.next()!!.type == TokenType.PLUS);
    assert(lexer.next()!!.type == TokenType.MINUS);
    assert(lexer.next()!!.type == TokenType.STAR);
    assert(lexer.next()!!.type == TokenType.SLASH);
    assert(lexer.next()!!.type == TokenType.ASSIGN);
    assert(lexer.next()!!.type == TokenType.EOF);
}

fn void lexer_number_value() @test {
    Lexer lexer;
    lexer.init("42");
    Token token = lexer.next()!!;
    assert(token.type == TokenType.NUMBER);
    assert(token.value == "42");
    assert(lexer.next()!!.type == TokenType.EOF);
}

fn void lexer_decimal_number() @test {
    Lexer lexer;
    lexer.init("3.14");
    Token token = lexer.next()!!;
    assert(token.type == TokenType.NUMBER);
    assert(token.value == "3.14");
}

fn void lexer_no_spaces() @test {
    // Regression test: the char after a number must not be swallowed
    Lexer lexer;
    lexer.init("12+34");
    Token first = lexer.next()!!;
    assert(first.type == TokenType.NUMBER);
    assert(first.value == "12");
    assert(lexer.next()!!.type == TokenType.PLUS);
    Token second = lexer.next()!!;
    assert(second.type == TokenType.NUMBER);
    assert(second.value == "34");
    assert(lexer.next()!!.type == TokenType.EOF);
}

fn void lexer_skips_whitespace() @test {
    // \n is NOT whitespace (it ends statements); \r still is
    Lexer lexer;
    lexer.init(" \t 7 \r + \t 8 ");
    assert(lexer.next()!!.type == TokenType.NUMBER);
    assert(lexer.next()!!.type == TokenType.PLUS);
    assert(lexer.next()!!.type == TokenType.NUMBER);
    assert(lexer.next()!!.type == TokenType.EOF);
}

fn void lexer_newline_is_a_token() @test {
    Lexer lexer;
    lexer.init("1\n2");
    assert(lexer.next()!!.type == TokenType.NUMBER);
    assert(lexer.next()!!.type == TokenType.NEW_LINE);
    assert(lexer.next()!!.type == TokenType.NUMBER);
    assert(lexer.next()!!.type == TokenType.EOF);
}

fn void lexer_var_declaration_tokens() @test {
    Lexer lexer;
    lexer.init("var x = 5\nx + 1");
    assert(lexer.next()!!.type == TokenType.VAR);
    Token ident = lexer.next()!!;
    assert(ident.type == TokenType.IDENTIFIER);
    assert(ident.value == "x");
    assert(lexer.next()!!.type == TokenType.ASSIGN);
    assert(lexer.next()!!.type == TokenType.NUMBER);
    assert(lexer.next()!!.type == TokenType.NEW_LINE);
    assert(lexer.next()!!.type == TokenType.IDENTIFIER);
    assert(lexer.next()!!.type == TokenType.PLUS);
    assert(lexer.next()!!.type == TokenType.NUMBER);
    assert(lexer.next()!!.type == TokenType.EOF);
}

fn void lexer_identifier_value() @test {
    Lexer lexer;
    lexer.init("foo_1 + 2");
    Token token = lexer.next()!!;
    assert(token.type == TokenType.IDENTIFIER);
    assert(token.value == "foo_1");
}

fn void lexer_keyword_prefix_is_identifier() @test {
    // "variable" starts with "var" but must lex as one identifier
    Lexer lexer;
    lexer.init("variable");
    Token token = lexer.next()!!;
    assert(token.type == TokenType.IDENTIFIER);
    assert(token.value == "variable");
    assert(lexer.next()!!.type == TokenType.EOF);
}

fn void lexer_peek_does_not_consume() @test {
    Lexer lexer;
    lexer.init("1 + 2");
    assert(lexer.next()!!.type == TokenType.NUMBER);
    assert(lexer.peek()!!.type == TokenType.PLUS);
    // peek must not have moved the lexer
    assert(lexer.next()!!.type == TokenType.PLUS);
    assert(lexer.next()!!.type == TokenType.NUMBER);
}

fn void lexer_error_on_illegal_char() @test {
    Lexer lexer;
    lexer.init("@");
    Token? token = lexer.next();
    if (catch excuse = token) {
        assert(excuse == LEXER_ERROR);
        assert(lexer.error.message == "Invalid token");
        return;
    }
    unreachable("expected a lexer error");
}

fn void lexer_error_on_malformed_number() @test {
    Lexer lexer;
    lexer.init("1.2.3");
    Token? token = lexer.next();
    if (catch excuse = token) {
        assert(excuse == LEXER_ERROR);
        assert(lexer.error.message == "Invalid number format");
        return;
    }
    unreachable("expected a lexer error");
}

// --- Parser ---

fn void parser_number_node() @test {
    Lexer lexer;
    Expression* exp = parse_source("5", &lexer);
    defer free_expression(exp);
    assert(exp.kind == ExpressionKind.NUMBER);
    assert(math::abs(exp.num.number - 5.0) < 0.0001);
}

fn void parser_binary_node() @test {
    Lexer lexer;
    Expression* exp = parse_source("1 + 2", &lexer);
    defer free_expression(exp);
    assert(exp.kind == ExpressionKind.BINARY);
    assert(exp.bin.operator == '+');
    assert(exp.bin.left.kind == ExpressionKind.NUMBER);
    assert(exp.bin.right.kind == ExpressionKind.NUMBER);
}

fn void parser_precedence_shape() @test {
    // 1 + 2 * 3 must parse as 1 + (2 * 3): '*' nested under '+'
    Lexer lexer;
    Expression* exp = parse_source("1 + 2 * 3", &lexer);
    defer free_expression(exp);
    assert(exp.kind == ExpressionKind.BINARY);
    assert(exp.bin.operator == '+');
    assert(exp.bin.left.kind == ExpressionKind.NUMBER);
    assert(exp.bin.right.kind == ExpressionKind.BINARY);
    assert(exp.bin.right.bin.operator == '*');
}

fn void parser_var_declaration() @test {
    Lexer lexer;
    lexer.init("var x = 1 + 2");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    assert(program.len() == 1);
    Statement* statement = program[0];
    assert(statement.kind == StatementKind.VAR_DECLARATION);
    assert(statement.var_dec.name == "x");
    assert(statement.var_dec.rhs_expression.kind == ExpressionKind.BINARY);
}

fn void parser_var_assignment() @test {
    Lexer lexer;
    lexer.init("x = 5");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    assert(program.len() == 1);
    Statement* statement = program[0];
    assert(statement.kind == StatementKind.VAR_ASSIGN);
    assert(statement.var_assign.name == "x");
    assert(statement.var_assign.rhs_expression.kind == ExpressionKind.NUMBER);
}

fn void parser_identifier_expression_is_not_assignment() @test {
    // A bare identifier in an expression must stay an expression statement
    Lexer lexer;
    lexer.init("x * 2");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    assert(program.len() == 1);
    Statement* statement = program[0];
    assert(statement.kind == StatementKind.EXPRESSION);
    Expression* exp = statement.exp.expression;
    assert(exp.kind == ExpressionKind.BINARY);
    assert(exp.bin.operator == '*');
    assert(exp.bin.left.kind == ExpressionKind.IDENTIFIER);
    assert(exp.bin.left.ident.identifier == "x");
    assert(exp.bin.right.kind == ExpressionKind.NUMBER);
}

fn void parser_program_skips_blank_lines() @test {
    Lexer lexer;
    lexer.init("var x = 1\n\n\nvar y = 2\nx + y\n");
    Parser parser;
    parser.init(&lexer)!!;
    Program program = parser.parse_program()!!;
    defer free_program(&program);

    assert(program.len() == 3);
    assert(program[0].kind == StatementKind.VAR_DECLARATION);
    assert(program[1].kind == StatementKind.VAR_DECLARATION);
    assert(program[1].var_dec.name == "y");
    assert(program[2].kind == StatementKind.EXPRESSION);
}

fn void parser_error_missing_paren() @test {
    assert_parse_error("(1 + 2", "Missing closing parentheses");
}

fn void parser_error_var_without_identifier() @test {
    assert_parse_error("var 5 = 3", "var must be followed by an identifier");
}

fn void parser_error_in_right_operand() @test {
    // The already-parsed left operand ("1") must be freed when the
    // right side of the binary expression fails
    assert_parse_error("1 + (2", "Missing closing parentheses");
}

fn void parser_error_lexer_error_mid_expression() @test {
    // The already-built number node must be freed when advancing
    // to the next token fails inside parse_factor
    assert_parse_error("1 @", "Invalid token", LEXER_ERROR);
}

fn void parser_error_var_missing_terminator() @test {
    // The already-parsed rhs must be freed when the statement
    // doesn't end at a newline/EOF
    assert_parse_error("var x = 1 2", "variable declaration must end with a new line or eof");
}

fn void parser_error_message_survives_peek() @test {
    // The lexer fault surfaces through peek() in parse_statement's
    // IDENTIFIER arm; the error message must still reach the parser
    assert_parse_error("x @", "Invalid token", LEXER_ERROR);
}

fn void parser_error_frees_earlier_statements() @test {
    // Statements already parsed into the program must be freed
    // when a later statement fails
    assert_parse_error("var x = 1\n(2 + 3", "Missing closing parentheses");
}

// --- Evaluation (end to end) ---

fn void eval_addition() @test {
    assert_eval("1 + 2", 3.0);
}

fn void eval_precedence() @test {
    assert_eval("1 + 2 * 3", 7.0);
    assert_eval("1 - 6 / 2", -2.0);
}

fn void eval_parentheses() @test {
    assert_eval("(1 + 2) * 3", 9.0);
    assert_eval("2 * (3 + 4)", 14.0);
}

fn void eval_left_associativity() @test {
    assert_eval("1 - 2 - 3", -4.0);
    assert_eval("16 / 4 / 2", 2.0);
}

fn void eval_division_fraction() @test {
    assert_eval("10 / 4", 2.5);
}

fn void eval_decimals() @test {
    assert_eval("3.5 + 1.5", 5.0);
    assert_eval("0.1 * 10", 1.0);
}

fn void eval_nested_parens() @test {
    assert_eval("((1 + 2) * (3 + 1)) / 6", 2.0);
}

fn void eval_single_number() @test {
    assert_eval("42", 42.0);
}

fn void eval_variable_use() @test {
    assert_eval("var x = 2\nx * 3", 6.0);
}

fn void eval_multiple_variables() @test {
    assert_eval("var a = 1\nvar b = 2\na + b", 3.0);
}

fn void eval_variable_from_variable() @test {
    assert_eval("var a = 2\nvar b = a * 3\nb + 1", 7.0);
}

fn void eval_variable_in_expression() @test {
    assert_eval("var x = 1.5\n(x + x) * 2", 6.0);
}

fn void eval_variable_assignment() @test {
    assert_eval("var x = 1\nx = x + 2\nx", 3.0);
}

fn void eval_assignment_overwrites() @test {
    assert_eval("var x = 2\nx = 10\nx * 2", 20.0);
}

fn void eval_error_redeclaration() @test {
    assert_runtime_error("var x = 1\nvar x = 2");
}

fn void eval_error_undefined_reference() @test {
    assert_runtime_error("y + 1");
}

fn void eval_error_assign_to_undefined() @test {
    assert_runtime_error("x = 5");
}

fn void eval_error_division_by_zero() @test {
    assert_runtime_error("1 / 0");
}
