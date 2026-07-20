module calc_comp;
import std::io;

enum ExpressionKind : short
{
	NUMBER,
	BINARY
}

struct NumberExpression
{
	float number;
}

struct BinaryExpression
{
	Expression* left;
	Expression* right;
	char operator;
}

struct Expression
{
	ExpressionKind kind;
	union
	{
		NumberExpression num;
		BinaryExpression bin;
	}
}

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
