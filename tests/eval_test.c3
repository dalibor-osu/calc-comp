module calc_comp;

// --- Evaluation: arithmetic, variables, types (end to end) ---
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

fn void eval_bool_literals() @test {
    assert_eval_bool("true", true);
    assert_eval_bool("false", false);
}

// --- Variables ---

fn void eval_variable_use() @test {
    assert_eval("var x: float = 2\nx * 3", 6.0);
}

fn void eval_multiple_variables() @test {
    assert_eval("var a: float = 1\nvar b: float = 2\na + b", 3.0);
}

fn void eval_variable_from_variable() @test {
    assert_eval("var a: float = 2\nvar b: float = a * 3\nb + 1", 7.0);
}

fn void eval_variable_in_expression() @test {
    assert_eval("var x: float = 1.5\n(x + x) * 2", 6.0);
}

fn void eval_variable_assignment() @test {
    assert_eval("var x: float = 1\nx = x + 2\nx", 3.0);
}

fn void eval_assignment_overwrites() @test {
    assert_eval("var x: float = 2\nx = 10\nx * 2", 20.0);
}

fn void eval_var_init_evaluates_initializer_once() @test {
    // The initializer must run exactly once — observable via a fn
    // that mutates a global
    assert_eval("var c: float = 0\nfn bump(): float {\nc = c + 1\nreturn c\n}\nvar y: float = bump()\nc", 1.0);
}

fn void eval_bool_variable() @test {
    assert_eval_bool("var b: bool = true\nb", true);
}

fn void eval_bool_variable_assignment() @test {
    assert_eval_bool("var b: bool = true\nb = false\nb", false);
}

// --- Type errors ---

fn void eval_error_bool_arithmetic() @test {
    // Arithmetic requires floats
    assert_runtime_error("true + true");
}

fn void eval_error_mixed_operand_types() @test {
    assert_runtime_error("1 + true");
}

fn void eval_error_var_init_type_mismatch() @test {
    // Declared type must match the initializer's value
    assert_runtime_error("var x: bool = 5");
}

fn void eval_error_var_init_type_mismatch_float() @test {
    assert_runtime_error("var x: float = true");
}

fn void eval_error_assign_type_mismatch() @test {
    // Assignment must match the variable's declared type
    assert_runtime_error("var x: float = 1\nx = true");
}

fn void eval_error_assign_type_mismatch_bool() @test {
    assert_runtime_error("var b: bool = true\nb = 1");
}

// --- Runtime errors (non-type) ---

fn void eval_error_redeclaration() @test {
    assert_runtime_error("var x: float = 1\nvar x: float = 2");
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
