module calc_comp;
import std::collections::result;
import std::io;

enum TokenType : int
{
	IDENTIFIER,
	NUMBER,

	VAR,
    FN,
    RETURN,
	TRUE,
	FALSE,
	FLOAT,
	BOOL,
	VOID,

	PLUS,
	MINUS,
	STAR,
	SLASH,
	ASSIGN,

	L_PAREN,
	R_PAREN,
    L_BRACE,
    R_BRACE,
	NEW_LINE,
    COMMA,
	COLON,

	EOF
}

struct Token
{
	TokenType type;
	String value;
}

struct Lexer
{
	String source;
	uint read_position;
	char current_char;
    Error error;
}

fn void Lexer.init(&self, String content)
{
	*self = { .source = content, .read_position = 0, .current_char = 0 };
}

fn void Lexer.read_char(&self)
{
	self.current_char = self.read_position >= self.source.len ? '\0' : self.source[self.read_position];
	self.read_position++;
}

fn Token? Lexer.read_number(&self)
{
	uint start    = self.read_position - 1;
	bool read_dot = false;
	while (self.current_char.is_number() || self.current_char == '.')
	{
		if (self.current_char == '.')
		{
			if (read_dot)
			{
                self.error = { .message = "Invalid number format" };
                return LEXER_ERROR~;
			}

			read_dot = true;
		}
		self.read_char();
	}

	return { .type = TokenType.NUMBER, .value = self.source[start..self.read_position - 2] };
}

fn Token lookup_keyword(String* value)
{
	switch(*value)
	{
		case "var":
			return { .type = TokenType.VAR, .value = "var" };
		case "fn":
			return { .type = TokenType.FN, .value = "fn" };
		case "return":
			return { .type = TokenType.RETURN, .value = "return" };
		case "true":
			return { .type = TokenType.TRUE, .value = "true" };
		case "false":
			return { .type = TokenType.FALSE, .value = "false" };
		case "float":
			return { .type = TokenType.FLOAT, .value = "float" };
		case "bool":
			return { .type = TokenType.BOOL, .value = "bool" };
		case "void":
			return { .type = TokenType.VOID, .value = "void" };
		default:
			return { .type = TokenType.IDENTIFIER, .value = *value };
	}
}

fn Token Lexer.read_identifier(&self) {
	uint start    = self.read_position - 1;
	while (self.current_char.is_valid_identifier_char())
	{
		self.read_char();
	}

	String value = self.source[start..self.read_position - 2];
	return lookup_keyword(&value);
}

fn void Lexer.skip_whitespace(&self)
{
	bool break_loop = false;
	while (!break_loop)
	{
		switch (self.current_char)
		{
			case ' ':
			case '\t':
			case '\r':
				self.read_char();
				continue;
			default:
				break_loop = true;
		}
	}
}

fn Token? Lexer.peek(&self)
{
    uint pos = self.read_position;
    char c = self.current_char;

    Token? next = self.next();
    self.read_position = pos;
    self.current_char = c;

    return next;
}

fn Token? Lexer.next(&self)
{
	Token token;
	if (self.current_char == '\0' && self.read_position == 0)
	{
		self.read_char();
	}

	self.skip_whitespace();

	switch (self.current_char)
	{
		case '(':
			token = { .type = TokenType.L_PAREN, .value = "(" };
			break;
		case ')':
			token = { .type = TokenType.R_PAREN, .value = ")" };
			break;
		case '{':
			token = { .type = TokenType.L_BRACE, .value = "{" };
			break;
		case '}':
			token = { .type = TokenType.R_BRACE, .value = "}" };
			break;
		case '+':
			token = { .type = TokenType.PLUS, .value = "+" };
			break;
		case '-':
			token = { .type = TokenType.MINUS, .value = "-" };
			break;
		case '*':
			token = { .type = TokenType.STAR, .value = "*" };
			break;
		case '=':
			token = { .type = TokenType.ASSIGN, .value = "=" };
			break;
		case '/':
			token = { .type = TokenType.SLASH, .value = "/" };
			break;
		case ',':
			token = { .type = TokenType.COMMA, .value = "," };
			break;
		case ':':
			token = { .type = TokenType.COLON, .value = ":" };
			break;
		case '\n':
			token = { .type = TokenType.NEW_LINE, .value = "\n" };
			break;
		case '\0':
			token = { .type = TokenType.EOF, .value = "\0" };
			break;

		default:
			if (self.current_char.is_number())
			{
				return self.read_number();
			}

			if (self.current_char.is_letter())
			{
				return self.read_identifier();
			}

            self.error = { .message = "Invalid token" };
            return LEXER_ERROR~;
	}

	self.read_char();
	return token;
}
