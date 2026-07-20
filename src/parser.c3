module calc_comp;
import std::io;
import std::collections::list;

alias Program = List {Statement*};

struct Parser
{
	Lexer* lexer;
	Token current;
}

fn void Parser.init(Parser* this, Lexer* lexer)
{
	this.lexer = lexer;
	this.advance();
}

fn void Parser.advance(Parser* this)
{
	this.current = this.lexer.next();
}

fn void Parser.expect(Parser* this, TokenType type, String message = "")
{
	if (this.current.type == type)
	{
		return;
	}

	if (message == "")
	{
		io::printn("Invalid token");
	}
	else
	{
		io::printfn("%s", message);
	}

	exit();
}

fn void Parser.expect_any(Parser* this, TokenType ...types)
{
	if (array::contains(types, this.current.type))
	{
		return;
	}

	io::printn("Invalid token");
	exit();
}

fn Program Parser.parse_program(Parser* this)
{
	Program program;
	program.init(mem);
	while (this.current.type != EOF)
	{
		if (this.current.type == NEW_LINE)
		{
			this.advance();
			continue;
		}

		program.push(this.parse_statement());
	}

	return program;
}

fn Statement* Parser.parse_statement(Parser* this)
{
	Statement* result = mem::new(Statement);
	switch (this.current.type)
	{
		case VAR:
			this.advance();
			this.expect(IDENTIFIER, "var must be followed by an identifier");

			String name = this.current.value;
			this.advance();
			this.expect(ASSIGN, "variable identifier must be followd by equals sign");

			this.advance();
			Expression* rhs = this.parse_expression();
			this.expect_any(NEW_LINE, EOF);

			*result = { .kind = VAR_DECLARATION, .var_dec = { .name = name, .rhs_expression = rhs } };
			break;
		default:
			*result = { .kind = EXPRESSION, .exp = { .expression = this.parse_expression() } };
			break;
	}

	return result;
}

fn Expression* Parser.parse_expression(Parser* this)
{
	Expression* left = this.parse_term();

	while (this.current.type == PLUS || this.current.type == MINUS)
	{
		char op = this.current.value[0];
		this.advance();
		Expression* right = this.parse_term();

		Expression* node = mem::new(Expression);
		*node = { .kind = BINARY, .bin = { .left = left, .right = right, .operator = op } };
		left = node;
	}
	return left;
}

fn Expression* Parser.parse_term(Parser* this)
{
	Expression* left = this.parse_factor();

	while (this.current.type == STAR || this.current.type == SLASH)
	{
		char op = this.current.value[0];
		this.advance();
		Expression* right = this.parse_factor();

		Expression* node = mem::new(Expression);
		*node = { .kind = BINARY, .bin = { .left = left, .right = right, .operator = op } };
		left = node;
	}
	return left;
}

fn Expression* Parser.parse_factor(Parser* this)
{
	switch (this.current.type)
	{
		case NUMBER:
			Expression* node = mem::new(Expression);
			*node = { .kind = NUMBER, .num = { String.to_float(this.current.value)!! } };
			this.advance();
			return node;
		case L_PAREN:
			this.advance();
			Expression* result = this.parse_expression();
			if (this.current.type != R_PAREN)
			{
				io::printfn("Missing closing paren: %d", this.current.type.ordinal);
				exit();
			}
			this.advance();
			return result;
		default:
			io::printfn("Invalid token");
			exit();
	}
}
