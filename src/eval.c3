module calc_comp;
import std::collections::map;
import std::io;

fn float? eval_binary(BinaryExpression* binExp, Environment* env)
{
	switch (binExp.operator)
	{
		case '+': return eval_expression(binExp.left, env)! + eval_expression(binExp.right, env)!;
		case '-': return eval_expression(binExp.left, env)! - eval_expression(binExp.right, env)!;
		case '*': return eval_expression(binExp.left, env)! * eval_expression(binExp.right, env)!;
		case '/':
            float rhs = eval_expression(binExp.right, env)!;
            if (rhs == 0)
            {
			    io::printn("Division by zero");
                return RUNTIME_ERROR~;
            }
            return eval_expression(binExp.left, env)! / rhs;
		default:
			io::printn("Invalid operator");
            return RUNTIME_ERROR~;
	}
}

fn float? eval_expression(Expression* exp, Environment* env)
{
	switch (exp.kind)
	{
		case NUMBER:
			return exp.num.number;
		case BINARY:
			return eval_binary(&exp.bin, env)!;
        case IDENTIFIER:
            return env.lookup_var(exp.ident.identifier)!;
        case CALL:
			CallExpression call = exp.call;
			FnDeclarationWithScope scopedDec = env.lookup_fn(call.name)!;
			uint parameterCount = scopedDec.declaration.parameter_count;
			if (parameterCount != call.parameter_count)
			{
				io::printfn("Invalid fn call: fn '%s' expected %d parameters, got %d", call.name, parameterCount, call.parameter_count);
				return RUNTIME_ERROR~;
			}

			Environment* callScope = mem::new(Environment).init(mem, scopedDec.scope);
			defer {
				callScope.free();
				free(callScope);
			}

			for (uint i = 0; i < parameterCount; i++)
			{
				String parameterName = scopedDec.declaration.parameters.@item_at(i);
				Expression* parameterExpression = call.parameters.@item_at(i);
				float value = eval_expression(parameterExpression, env)!;
				callScope.declare_var(parameterName, value)!;
			}

			foreach (statement : scopedDec.declaration.body)
			{
				if (statement.kind == RETURN)
				{
					return eval_expression(statement.ret.expression, callScope)!;
				}

				eval_statement(statement, callScope)!;
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
			env.declare_var(statement.var_dec.name, eval_expression(statement.var_dec.rhs_expression, env)!)!;
            break;
        case FN_DECLARATION:
			env.declare_fn(&statement.fn_dec)!;
            break;
        case VAR_ASSIGN:
			env.assign_var(statement.var_assign.name, eval_expression(statement.var_assign.rhs_expression, env)!)!;
            break;
        case EXPRESSION:
            float result = eval_expression(statement.exp.expression, env)!;
            io::printfn("%f", result);
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
