module calc_comp;
import std::math;

// --- Parser: expressions, variables, errors ---
// (Function parsing tests live in functions_test.c3)

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
