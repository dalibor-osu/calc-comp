module calc_comp;
import std::collections::map;
import std::io;

const Type[] ALLOWED_MATH_TYPES = { Type.FLOAT };

fn Value? eval_binary(BinaryExpression* bin_exp, Environment* env)
{
	Value left = eval_expression(bin_exp.left, env)!;
	Value right = eval_expression(bin_exp.right, env)!;
	if (left.type != right.type) 
	{
		io::printn("Can not evaluate different types");
		return RUNTIME_ERROR~;
	}

	if (!array::contains(ALLOWED_MATH_TYPES, left.type))
	{
		io::printfn("Can not evaluate type: %s", left.type.description);
		return RUNTIME_ERROR~;
	}

	switch (bin_exp.operator)
	{
		case '+': 
			return { .type = FLOAT, .float_val = left.float_val + right.float_val };
		case '-': ;
			return { .type = FLOAT, .float_val = left.float_val - right.float_val };
		case '*': ;
			return { .type = FLOAT, .float_val = left.float_val * right.float_val };
		case '/':
            if (right.float_val == 0)
            {
			    io::printn("Division by zero");
                return RUNTIME_ERROR~;
            }
			return { .type = FLOAT, .float_val = left.float_val / right.float_val };
		default:
			io::printn("Invalid operator");
            return RUNTIME_ERROR~;
	}
}

fn Value? eval_expression(Expression* exp, Environment* env)
{
	switch (exp.kind)
	{
		case NUMBER:
			return { .type = FLOAT, .float_val = exp.float_val.value };
		case BOOL:
			return { .type = BOOL, .bool_val = exp.bool_val.value };
		case BINARY:
			return eval_binary(&exp.bin, env)!;
        case IDENTIFIER:
            return env.lookup_var(exp.ident.identifier)!;
        case CALL:
			CallExpression call = exp.call;
			FnDeclarationWithScope scoped_dec = env.lookup_fn(call.name)!;
			uint parameter_count = scoped_dec.declaration.parameter_count;
			if (parameter_count != call.parameter_count)
			{
				io::printfn("Invalid fn call: fn '%s' expected %d parameters, got %d", call.name, parameter_count, call.parameter_count);
				return RUNTIME_ERROR~;
			}

			Environment* call_scope = mem::new(Environment).init(mem, scoped_dec.scope);
			defer {
				call_scope.free();
				free(call_scope);
			}

			for (uint i = 0; i < parameter_count; i++)
			{
				NameTypePair parameter_def = scoped_dec.declaration.parameters.@item_at(i);
				Expression* parameter_expression = call.parameters.@item_at(i);
				Value value = eval_expression(parameter_expression, env)!;
				if (value.type != parameter_def.type)
				{
					io::printfn("invalid parameter provided. expected '%s', got '%s'", parameter_def.type.description, value.type.description);
					return RUNTIME_ERROR~;
				}
				call_scope.declare_var(parameter_def.name, value)!;
			}

			foreach (statement : scoped_dec.declaration.body)
			{
				if (statement.kind == RETURN)
				{
					Value value = statement.ret.expression == null ? { .type = VOID } : eval_expression(statement.ret.expression, call_scope)!;
					if (value.type != scoped_dec.declaration.return_type)
					{
						io::printfn("invalid type returned. expected '%s', got '%s'", scoped_dec.declaration.return_type.description, value.type.description);
						return RUNTIME_ERROR~;
					}

					return value;
				}

				eval_statement(statement, call_scope)!;
			}

			if (scoped_dec.declaration.return_type == VOID)
			{
				return { .type = VOID };
			}

			io::printfn("Missing return statement");
            return RUNTIME_ERROR~; 
	}
}

fn void? eval_statement(Statement* statement, Environment* env)
{
    switch(statement.kind)
    {
        case VAR_DECLARATION:
			Value value = eval_expression(statement.var_dec.rhs_expression, env)!;
			if (value.type != statement.var_dec.type)
			{
				io::printfn("invalid value provided in variable declaration. expected '%s', got '%s'", statement.var_dec.type.description, value.type.description);
            	return RUNTIME_ERROR~; 
			}
			env.declare_var(statement.var_dec.name, value)!;
            break;
        case FN_DECLARATION:
			env.declare_fn(&statement.fn_dec)!;
            break;
        case VAR_ASSIGN:
			env.assign_var(statement.var_assign.name, eval_expression(statement.var_assign.rhs_expression, env)!)!;
            break;
        case EXPRESSION:
            Value result = eval_expression(statement.exp.expression, env)!;
			switch(result.type)
			{
				case FLOAT:
            		io::printfn("%f", result.float_val);
				case BOOL:
            		io::printfn("%s", result.bool_val ? "true" : "false");
				default:
			}
        case RETURN:
            io::printfn("Unexpected return");
			return RUNTIME_ERROR~;
    }
}

fn void? eval_program(Program* program)
{
    Environment* env = mem::new(Environment).init(mem);
    defer {
		env.free();
		free(env);
	}

    foreach(statement : program)
    {
        eval_statement(statement, env)!;
    }
}
