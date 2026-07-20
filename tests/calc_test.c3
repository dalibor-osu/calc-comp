module calc_comp;
import std::math;

// AI generated test lolololololololo

fn Expression* parse_source(String source, Lexer* lexer) {
    *lexer = { .source = source };
    Parser parser = { .lexer = lexer };
    parser.advance();
    return parser.parse_expression();
}

// Evaluates a whole program and returns the value of the last expression
// statement (without printing it).
fn float eval_source(String source) {
    Lexer lexer;
    lexer.init(source);
    Parser parser;
    parser.init(&lexer);
    Program program = parser.parse_program();
    defer free_program(&program);

    Environment env;
    env.init(mem);
    defer env.free();

    float result = 0;
    foreach (statement : program) {
        switch (statement.kind) {
            case VAR_DECLARATION:
                eval_statement(statement, &env);
            case EXPRESSION:
                result = eval_expression(statement.exp.expression, &env);
        }
    }
    return result;
}

fn void assert_eval(String source, float expected) {
    float result = eval_source(source);
    assert(math::abs(result - expected) < 0.0001, "wrong result for expression");
}

// --- Lexer ---

fn void lexer_single_char_tokens() @test {
    Lexer lexer = { .source = "( ) + - * /" };
    assert(lexer.next().type == TokenType.L_PAREN);
    assert(lexer.next().type == TokenType.R_PAREN);
    assert(lexer.next().type == TokenType.PLUS);
    assert(lexer.next().type == TokenType.MINUS);
    assert(lexer.next().type == TokenType.STAR);
    assert(lexer.next().type == TokenType.SLASH);
    assert(lexer.next().type == TokenType.EOF);
}

fn void lexer_number_value() @test {
    Lexer lexer = { .source = "42" };
    Token token = lexer.next();
    assert(token.type == TokenType.NUMBER);
    assert(token.value == "42");
    assert(lexer.next().type == TokenType.EOF);
}

fn void lexer_decimal_number() @test {
    Lexer lexer = { .source = "3.14" };
    Token token = lexer.next();
    assert(token.type == TokenType.NUMBER);
    assert(token.value == "3.14");
}

fn void lexer_no_spaces() @test {
    // Regression test: the char after a number must not be swallowed
    Lexer lexer = { .source = "12+34" };
    Token first = lexer.next();
    assert(first.type == TokenType.NUMBER);
    assert(first.value == "12");
    assert(lexer.next().type == TokenType.PLUS);
    Token second = lexer.next();
    assert(second.type == TokenType.NUMBER);
    assert(second.value == "34");
    assert(lexer.next().type == TokenType.EOF);
}

fn void lexer_skips_whitespace() @test {
    // \n is NOT whitespace anymore (it ends statements); \r still is
    Lexer lexer = { .source = " \t 7 \r + \t 8 " };
    assert(lexer.next().type == TokenType.NUMBER);
    assert(lexer.next().type == TokenType.PLUS);
    assert(lexer.next().type == TokenType.NUMBER);
    assert(lexer.next().type == TokenType.EOF);
}

fn void lexer_newline_is_a_token() @test {
    Lexer lexer = { .source = "1\n2" };
    assert(lexer.next().type == TokenType.NUMBER);
    assert(lexer.next().type == TokenType.NEW_LINE);
    assert(lexer.next().type == TokenType.NUMBER);
    assert(lexer.next().type == TokenType.EOF);
}

fn void lexer_var_declaration_tokens() @test {
    Lexer lexer = { .source = "var x = 5\nx + 1" };
    assert(lexer.next().type == TokenType.VAR);
    Token ident = lexer.next();
    assert(ident.type == TokenType.IDENTIFIER);
    assert(ident.value == "x");
    assert(lexer.next().type == TokenType.ASSIGN);
    assert(lexer.next().type == TokenType.NUMBER);
    assert(lexer.next().type == TokenType.NEW_LINE);
    assert(lexer.next().type == TokenType.IDENTIFIER);
    assert(lexer.next().type == TokenType.PLUS);
    assert(lexer.next().type == TokenType.NUMBER);
    assert(lexer.next().type == TokenType.EOF);
}

fn void lexer_identifier_value() @test {
    Lexer lexer = { .source = "foo_1 + 2" };
    Token token = lexer.next();
    assert(token.type == TokenType.IDENTIFIER);
    assert(token.value == "foo_1");
}

fn void lexer_keyword_prefix_is_identifier() @test {
    // "variable" starts with "var" but must lex as one identifier
    Lexer lexer = { .source = "variable" };
    Token token = lexer.next();
    assert(token.type == TokenType.IDENTIFIER);
    assert(token.value == "variable");
    assert(lexer.next().type == TokenType.EOF);
}

fn void lexer_illegal_token() @test {
    // "a" is an identifier since variables were added; use a real illegal char
    Lexer lexer = { .source = "@" };
    assert(lexer.next().type == TokenType.ILLEGAL);
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
    parser.init(&lexer);
    Program program = parser.parse_program();
    defer free_program(&program);

    assert(program.len() == 1);
    Statement* statement = program[0];
    assert(statement.kind == StatementKind.VAR_DECLARATION);
    assert(statement.var_dec.name == "x");
    assert(statement.var_dec.rhs_expression.kind == ExpressionKind.BINARY);
}

fn void parser_expression_statement() @test {
    Lexer lexer;
    lexer.init("x * 2");
    Parser parser;
    parser.init(&lexer);
    Program program = parser.parse_program();
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
    parser.init(&lexer);
    Program program = parser.parse_program();
    defer free_program(&program);

    assert(program.len() == 3);
    assert(program[0].kind == StatementKind.VAR_DECLARATION);
    assert(program[1].kind == StatementKind.VAR_DECLARATION);
    assert(program[1].var_dec.name == "y");
    assert(program[2].kind == StatementKind.EXPRESSION);
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
