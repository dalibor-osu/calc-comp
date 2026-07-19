module calc_comp;
import std::math;

// AI generated test lolololololololo

fn Expression* parse_source(String source, Lexer* lexer) {
    *lexer = { .source = source };
    Parser parser = { .lexer = lexer };
    parser.advance();
    return parser.parse_expression();
}

fn float eval_source(String source) {
    Lexer lexer;
    Expression* exp = parse_source(source, &lexer);
    defer free_expression(exp);
    return eval(exp);
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
    Lexer lexer = { .source = " \t\n 7 \r\n + \t 8 " };
    assert(lexer.next().type == TokenType.NUMBER);
    assert(lexer.next().type == TokenType.PLUS);
    assert(lexer.next().type == TokenType.NUMBER);
    assert(lexer.next().type == TokenType.EOF);
}

fn void lexer_illegal_token() @test {
    Lexer lexer = { .source = "a" };
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
