module calc_comp;
import std::collections::map;
import std::io;

alias Environment = map::HashMap {String, float};

fn float eval_binary(BinaryExpression* binExp, Environment* env)
{
	switch (binExp.operator)
	{
		case '+': return eval_expression(binExp.left, env) + eval_expression(binExp.right, env);
		case '-': return eval_expression(binExp.left, env) - eval_expression(binExp.right, env);
		case '*': return eval_expression(binExp.left, env) * eval_expression(binExp.right, env);
		case '/': return eval_expression(binExp.left, env) / eval_expression(binExp.right, env);
		default:
			io::printn("Invalid operator");
			exit();
	}
}

fn float eval_expression(Expression* exp, Environment* env)
{
	switch (exp.kind)
	{
		case NUMBER:
			return exp.num.number;
		case BINARY:
			return eval_binary(&exp.bin, env);
        case IDENTIFIER:
            float? value = env.get(exp.ident.identifier);
            if (catch excuse = value)
            {
                io::printn("Undefined reference");
                exit();
            }

            return value;
	}
}

fn void eval_statement(Statement* statement, Environment* env)
{
    switch(statement.kind)
    {
        case VAR_DECLARATION:
            if (env.has_key(statement.var_dec.name))
            {
                io::printfn("Variable already defined: %s", statement.var_dec.name);
                exit();
            }

            float value = eval_expression(statement.var_dec.rhs_expression, env);
            env.set(statement.var_dec.name.copy(mem), value);
            break;
        case EXPRESSION:
            float result = eval_expression(statement.exp.expression, env);
            io::printfn("%f", result);
    }
}

fn void eval_program(Program* program)
{
    Environment* env = mem::new(Environment);
    defer free(env);

    env = env.init(mem);
    defer env.free();

    foreach(statement : program)
    {
        eval_statement(statement, env);
    }
}
