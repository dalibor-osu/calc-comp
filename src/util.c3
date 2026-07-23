module calc_comp;
import std::io;
import libc;

faultdef
    LEXER_ERROR,
    PARSER_ERROR,
    RUNTIME_ERROR;

struct Error { String message; }

fn bool char.is_number(char* this)
{
	return *this >= '0' && *this <= '9';
}

fn bool char.is_letter(char* this)
{
	return (*this >= 'a' && *this <= 'z') || (*this >= 'A' && *this <= 'Z');
}

fn bool char.is_valid_identifier_char(char* this)
{
	return (*this).is_letter() || (*this).is_number() || *this == '_';
}

// https://c3-lang.org/language-common/optionals-advanced/#file-reading-example
<*
 Function modifies 'buffer'
 Returns an Optional with a 'char[]' result
 OR an empty Optional with an Excuse
*>
fn char[]? read_file(String filename, char[] buffer)
{
	File file = file::open(filename, "r")!;
	defer (void)file.close();

	file.read(buffer)!;

	return buffer;
}

fn void free_expression(Expression* exp)
{
	switch(exp.kind) // No default branch on purpuse so the compiler forces handling when new kind is added
	{
		case BINARY:
			free_expression(exp.bin.left);
			free_expression(exp.bin.right);
			free(exp);
			break;
		case CALL:
			foreach(expression : exp.call.parameters) free_expression(expression);
			exp.call.parameters.free();
			free(exp);
			break;
		case NUMBER:
			free(exp);
			break;
		case IDENTIFIER:
			free(exp);
			break;
	}
}

fn void free_statement(Statement* statement)
{
    switch(statement.kind)
    {
        case VAR_DECLARATION:
            free_expression(statement.var_dec.rhs_expression);
            break;
        case FN_DECLARATION:
			foreach(st: statement.fn_dec.body) free_statement(st);
			statement.fn_dec.parameters.free();
			statement.fn_dec.body.free();
        case VAR_ASSIGN:
            free_expression(statement.var_assign.rhs_expression);
            break;
        case EXPRESSION:
            free_expression(statement.exp.expression);
		case RETURN:
            free_expression(statement.ret.expression);
            break;
    }

    free(statement);
}

fn void free_program(Program* program)
{
    foreach (statement : program)
    {
        free_statement(statement);
    }

    program.free();
}
