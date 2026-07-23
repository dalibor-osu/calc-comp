module calc_comp;

// --- Evaluation: arithmetic + variables (end to end) ---
// (Function evaluation tests live in functions_test.c3)

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
