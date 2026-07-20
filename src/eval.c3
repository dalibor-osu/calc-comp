module calc_comp;
import std::collections::map;
import std::io;

alias Environment = map::HashMap {String, float};

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
            float? value = env.get(exp.ident.identifier);
            if (catch excuse = value)
            {
                io::printfn("Undefined reference: %s", exp.ident.identifier);
                return RUNTIME_ERROR~;
            }

            return value;
	}
}

fn void? eval_statement(Statement* statement, Environment* env)
{
    switch(statement.kind)
    {
        case VAR_DECLARATION:
            if (env.has_key(statement.var_dec.name))
            {
                io::printfn("Variable already defined: %s", statement.var_dec.name);
                return RUNTIME_ERROR~;
            }

            float value = eval_expression(statement.var_dec.rhs_expression, env)!;
            env.set(statement.var_dec.name, value);
            break;
        case VAR_ASSIGN:
            if (!env.has_key(statement.var_assign.name))
            {
                io::printfn("Undefined reference: %s", statement.var_assign.name);
                return RUNTIME_ERROR~;
            }

            float value = eval_expression(statement.var_assign.rhs_expression, env)!;
            env.set(statement.var_assign.name, value);
            break;
        case EXPRESSION:
            float result = eval_expression(statement.exp.expression, env)!;
            io::printfn("%f", result);
    }
}

fn void? eval_program(Program* program)
{
    Environment* env = mem::new(Environment);
    defer free(env);

    env = env.init(mem);
    defer env.free();

    foreach(statement : program)
    {
        eval_statement(statement, env)!;
    }
}
