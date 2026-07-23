module calc_comp;

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

fn void lexer_braces_and_comma() @test {
    Lexer lexer;
    lexer.init("{ } ,");
    assert(lexer.next()!!.type == TokenType.L_BRACE);
    assert(lexer.next()!!.type == TokenType.R_BRACE);
    assert(lexer.next()!!.type == TokenType.COMMA);
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

fn void lexer_fn_declaration_tokens() @test {
    // Token stream of a full fn declaration
    Lexer lexer;
    lexer.init("fn add(a, b) {\nreturn a + b\n}");
    assert(lexer.next()!!.type == TokenType.FN);
    Token name = lexer.next()!!;
    assert(name.type == TokenType.IDENTIFIER);
    assert(name.value == "add");
    assert(lexer.next()!!.type == TokenType.L_PAREN);
    Token param_a = lexer.next()!!;
    assert(param_a.type == TokenType.IDENTIFIER);
    assert(param_a.value == "a");
    assert(lexer.next()!!.type == TokenType.COMMA);
    Token param_b = lexer.next()!!;
    assert(param_b.type == TokenType.IDENTIFIER);
    assert(param_b.value == "b");
    assert(lexer.next()!!.type == TokenType.R_PAREN);
    assert(lexer.next()!!.type == TokenType.L_BRACE);
    assert(lexer.next()!!.type == TokenType.NEW_LINE);
    assert(lexer.next()!!.type == TokenType.RETURN);
    assert(lexer.next()!!.type == TokenType.IDENTIFIER);
    assert(lexer.next()!!.type == TokenType.PLUS);
    assert(lexer.next()!!.type == TokenType.IDENTIFIER);
    assert(lexer.next()!!.type == TokenType.NEW_LINE);
    assert(lexer.next()!!.type == TokenType.R_BRACE);
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

fn void lexer_fn_keyword_prefix_is_identifier() @test {
    // "fnord" starts with "fn", "returning" starts with "return"
    Lexer lexer;
    lexer.init("fnord returning");
    Token first = lexer.next()!!;
    assert(first.type == TokenType.IDENTIFIER);
    assert(first.value == "fnord");
    Token second = lexer.next()!!;
    assert(second.type == TokenType.IDENTIFIER);
    assert(second.value == "returning");
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
