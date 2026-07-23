module calc_comp;
import std::math;

// Shared helpers for all test files in this directory.
// All test files live in the same module, so these are visible everywhere.

// Parses a single expression (not a whole program).
fn Expression* parse_source(String source, Lexer* lexer) {
    lexer.init(source);
    Parser parser;
    parser.init(lexer)!!;
    return parser.parse_expression()!!;
}

// Evaluates a whole program and returns the value of the last expression
// statement (without printing it). Non-expression statements (var, fn,
// assignment) are evaluated for their effects.
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
        if (statement.kind == StatementKind.EXPRESSION) {
            result = eval_expression(statement.exp.expression, &env)!!;
        } else {
            eval_statement(statement, &env)!!;
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
        assert(excuse == expected_fault, "unexpected fault kind");
        assert(parser.error.message == expected_message, "unexpected parser error message");
        return;
    }
    unreachable("expected a parse error");
}
