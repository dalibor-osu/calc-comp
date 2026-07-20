module calc_comp;
import std::io;
import std::collections::list;

alias Program = List {Statement*};

struct Parser
{
	Lexer* lexer;
	Token current;
    Error error;
}

fn void? Parser.init(Parser* this, Lexer* lexer)
{
	this.lexer = lexer;
	this.advance()!;
}

fn void? Parser.advance(Parser* this)
{
    Token? next = this.lexer.next();
    if (catch excuse = next)
    {
        this.error = this.lexer.error;
        return excuse~;
    }
    
    this.current = next;
}

fn void? Parser.expect(Parser* this, TokenType type, String message = "")
{
	if (this.current.type == type)
	{
		return;
	}

    this.error = { .message = message == "" ? "Invalid token type" : message };
    return PARSER_ERROR~;
}

fn void? Parser.expect_any(Parser* this, TokenType[] types, String message = "")
{
	if (array::contains(types, this.current.type))
	{
		return;
	}

    this.error = { .message = message == "" ? "Invalid token type" : message };
    return PARSER_ERROR~;
}

fn Program? Parser.parse_program(Parser* this)
{
	Program program;
	program.init(mem);
    defer catch {
        foreach (statement : program)
        {
            free_statement(statement);
        }
        program.free();
    }

	while (this.current.type != EOF)
	{
		if (this.current.type == NEW_LINE)
		{
			this.advance()!;
			continue;
		}

		program.push(this.parse_statement()!);
	}

	return program;
}

fn Statement*? Parser.parse_statement(Parser* this)
{
	Statement* result = mem::new(Statement);
    defer catch free(result);
	switch (this.current.type)
	{
		case VAR:
			this.advance()!;
			this.expect(IDENTIFIER, "var must be followed by an identifier")!;

			String name = this.current.value;
			this.advance()!;
			this.expect(ASSIGN, "variable identifier must be followd by equals sign")!;

			this.advance()!;
			Expression* rhs = this.parse_expression()!;
            defer catch free_expression(rhs);
			this.expect_any({ TokenType.NEW_LINE, TokenType.EOF }, "variable declaration must end with a new line or eof")!;

			*result = { .kind = VAR_DECLARATION, .var_dec = { .name = name, .rhs_expression = rhs } };
			break;
        case IDENTIFIER:
			String name = this.current.value;
            Token? next = this.lexer.peek();
            if (catch excuse = next)
            {
                this.error = this.lexer.error;
                return excuse~;
            }

            if (next.type != ASSIGN)
            {
			    *result = { .kind = EXPRESSION, .exp = { .expression = this.parse_expression()! } };
			    break;
            }

			this.advance()!;
			this.advance()!;
			Expression* rhs = this.parse_expression()!;
            defer catch free_expression(rhs);
			this.expect_any({ TokenType.NEW_LINE, TokenType.EOF }, "variable assignment must end with a new line or eof")!;

			*result = { .kind = VAR_ASSIGN, .var_assign = { .name = name, .rhs_expression = rhs } };
			break;
		default:
			*result = { .kind = EXPRESSION, .exp = { .expression = this.parse_expression()! } };
			break;
	}

	return result;
}

fn Expression*? Parser.parse_expression(Parser* this)
{
	Expression* left = this.parse_term()!;
    defer catch free_expression(left);

	while (this.current.type == PLUS || this.current.type == MINUS)
	{
		char op = this.current.value[0];
		this.advance()!;
		Expression* right = this.parse_term()!;

		Expression* node = mem::new(Expression);
		*node = { .kind = BINARY, .bin = { .left = left, .right = right, .operator = op } };
		left = node;
	}
	return left;
}

fn Expression*? Parser.parse_term(Parser* this)
{
	Expression* left = this.parse_factor()!;
    defer catch free_expression(left);

	while (this.current.type == STAR || this.current.type == SLASH)
	{
		char op = this.current.value[0];
		this.advance()!;
		Expression* right = this.parse_factor()!;

		Expression* node = mem::new(Expression);
		*node = { .kind = BINARY, .bin = { .left = left, .right = right, .operator = op } };
		left = node;
	}
	return left;
}

fn Expression*? Parser.parse_factor(Parser* this)
{
	switch (this.current.type)
	{
        case IDENTIFIER:
			Expression* node = mem::new(Expression);
            defer catch free(node);
			*node = { .kind = IDENTIFIER, .ident = { this.current.value } };
			this.advance()!;
			return node;
		case NUMBER:
			Expression* node = mem::new(Expression);
            defer catch free(node);
			*node = { .kind = NUMBER, .num = { String.to_float(this.current.value)!! } };
			this.advance()!;
			return node;
		case L_PAREN:
			this.advance()!;
			Expression* result = this.parse_expression()!;
            defer catch free_expression(result);
			if (this.current.type != R_PAREN)
			{
                this.error = { .message = "Missing closing parentheses" };
                return PARSER_ERROR~;
			}
			this.advance()!;
			return result;
		default:
            this.error = { .message = "Invalid token" };
            return PARSER_ERROR~;
	}
}
