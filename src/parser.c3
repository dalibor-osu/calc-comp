module calc_comp;
import std::io;
import std::collections::list;

alias Program = List {Statement*};
const TokenType[] ALLOWED_VARIABLE_TYPES = { TokenType.BOOL, TokenType.FLOAT };
const TokenType[] ALLOWED_FN_RETURN_TYPES = { TokenType.BOOL, TokenType.FLOAT, TokenType.VOID };

struct Parser
{
	Lexer* lexer;
	Token current;
    Error error;
}

fn void? Parser.init(&self, Lexer* lexer)
{
	self.lexer = lexer;
	self.advance()!;
}

fn void? Parser.advance(&self)
{
    Token? next = self.lexer.next();
    if (catch excuse = next)
    {
        self.error = self.lexer.error;
        return excuse~;
    }
    
    self.current = next;
}

fn Token? Parser.peek(&self)
{
    Token? next = self.lexer.peek();
    if (catch excuse = next)
    {
        self.error = self.lexer.error;
        return excuse~;
    }

    return next;
}

fn Type? Parser.get_type_by_token(&self, TokenType token_type)
{
	Type? type = get_type_by_token(token_type);
	if (catch excuse = type)
	{
		self.error = { .message = "no matching Type found for provided TokenType" };
		return PARSER_ERROR~;
	}

	return type;
}

fn void? Parser.expect(&self, TokenType type, String message = "")
{
	if (self.current.type == type)
	{
		return;
	}

    self.error = { .message = message == "" ? "Invalid token type" : message };
    return PARSER_ERROR~;
}


fn void? Parser.expect_next(&self, TokenType type, String message = "")
{
    Token next = self.peek()!;
	if (next.type == type)
	{
		return;
	}

    self.error = { .message = message == "" ? "Invalid token type" : message };
    return PARSER_ERROR~;
}

fn void? Parser.expect_any(&self, TokenType[] types, String message = "")
{
	if (array::contains(types, self.current.type))
	{
		return;
	}

    self.error = { .message = message == "" ? "Invalid token type" : message };
    return PARSER_ERROR~;
}

fn void? Parser.expect_next_any(&self, TokenType[] types, String message = "")
{
    Token next = self.peek()!;
	if (array::contains(types, next.type))
	{
		return;
	}

    self.error = { .message = message == "" ? "Invalid token type" : message };
    return PARSER_ERROR~;
}

fn Type? Parser.parse_variable_type(&self)
{
    self.expect_any(ALLOWED_VARIABLE_TYPES, "invalid variable type")!;
	Type? parameter_type = self.get_type_by_token(self.current.type);
	if (catch excuse = parameter_type)
	{
		self.error = { .message = "invalid variable type" };
		return PARSER_ERROR~;
	}

	return parameter_type;
}

fn NameTypePair? Parser.parse_variable_name_type_pair(&self)
{
	self.expect(IDENTIFIER, "invalid token in variable name declaration")!;
	String name = self.current.value;
	self.advance()!;

	self.expect(COLON, "variable identifier must be followed by type annotation (var <name>: <type> = <value>)")!;
	self.advance()!;
	Type type = self.parse_variable_type()!;
	self.advance()!;
	return { name, type };
}

fn Program? Parser.parse_program(&self)
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

	while (self.current.type != EOF)
	{
		if (self.current.type == NEW_LINE)
		{
			self.advance()!;
			continue;
		}

		program.push(self.parse_statement()!);
	}

	return program;
}

fn Statement? Parser.parse_statement_var(&self)
{
	self.advance()!;
	NameTypePair name_and_type = self.parse_variable_name_type_pair()!;

	self.expect(ASSIGN, "variable type must be followed by equals sign")!;

	self.advance()!;
	Expression* rhs = self.parse_expression()!;
    defer catch free_expression(rhs);
	self.expect_any({ TokenType.NEW_LINE, TokenType.EOF }, "variable declaration must end with a new line or eof")!;

	return { .kind = VAR_DECLARATION, .var_dec = { .name = name_and_type.name, .type = name_and_type.type, .rhs_expression = rhs } };
}

fn Statement? Parser.parse_statement_identifier(&self)
{
	String name = self.current.value;
    Token? next = self.lexer.peek();
    if (catch excuse = next)
    {
        self.error = self.lexer.error;
        return excuse~;
    }

    if (next.type != ASSIGN)
    {
	    return { .kind = EXPRESSION, .exp = { .expression = self.parse_expression()! } };
    }

	self.advance()!;
	self.advance()!;
	Expression* rhs = self.parse_expression()!;
    defer catch free_expression(rhs);
	self.expect_any({ TokenType.NEW_LINE, TokenType.EOF }, "variable assignment must end with a new line or eof")!;

	return { .kind = VAR_ASSIGN, .var_assign = { .name = name, .rhs_expression = rhs } };
}

fn Statement? Parser.parse_statement_fn(&self)
{
	self.advance()!;
	self.expect(IDENTIFIER, "missing or invalid function name")!;
    String name = self.current.value;

	self.advance()!;
	self.expect(L_PAREN, "function name must be followed by L_PAREN '('")!;

	self.advance()!;
    self.expect_any({ TokenType.R_PAREN, TokenType.IDENTIFIER }, "missing R_PAREN ')'")!;

    List {NameTypePair} parameters;
    parameters.init(mem);
    defer catch parameters.free();

	uint parameter_count = 0;
    while (self.current.type != R_PAREN)
    {
        switch(self.current.type)
        {
            case IDENTIFIER:
				NameTypePair parameter_def = self.parse_variable_name_type_pair()!;
                self.expect_any({ TokenType.COMMA, TokenType.R_PAREN}, "expected comma ',' or R_PAREN ')' after parameter name")!;
                parameters.push(parameter_def);
				parameter_count++;
                break;
            case COMMA:
                self.expect_next(IDENTIFIER, "missing parameter name after comma")!;
        		self.advance()!;
                break;
            default:
                self.error = { .message = "Invalid token" };
                return PARSER_ERROR~;
        }
    }

    self.advance()!;
	self.expect(COLON, "missing type annotation in fn declaration (fn <name>(<args>): <return_type> { <body> })")!;

    self.advance()!;
	self.expect_any(ALLOWED_FN_RETURN_TYPES, "invalid fn return type")!;
	Type return_type = self.get_type_by_token(self.current.type)!;

    self.advance()!;
	while(self.current.type == NEW_LINE) 
	{
		self.advance()!;
	}

    self.expect(L_BRACE, "start of a block expected")!;
    List {Statement*} body = self.parse_block(true)!;
	defer catch {
		foreach (statement : body) free_statement(statement);
		body.free();
	}

	sz body_len = body.len();
    if (return_type != VOID && (body_len == 0 || body.last()!.kind != StatementKind.RETURN))
    {
        self.error = { .message = "Missing return statement" };
        return PARSER_ERROR~;
    }
	
	// check return statements
	foreach (statement : body)
	{
		if (statement.kind != RETURN)
		{
			continue;
		}

		if (return_type == VOID && statement.ret.expression != null)
		{
			self.error = { .message = "invalid return statement; void fn can't return a value" };
			return PARSER_ERROR~;
		}

		if (return_type != VOID && statement.ret.expression == null)
		{
			self.error = { .message = "invalid return statement; fn with return type can't return void" };
			return PARSER_ERROR~;
		}
	}

    return { .kind = FN_DECLARATION, .fn_dec = { name, parameters, parameter_count, return_type, body } };
}

fn List {Statement*}? Parser.parse_block(&self, bool allow_return)
{
    if (self.current.type == L_BRACE)
    {
        self.advance()!;
    }

    List {Statement*} block;
    block.init(mem);
    defer catch {
        foreach (statement : block) free_statement(statement);
        block.free();
    }

    while (self.current.type != R_BRACE)
    {
        Token next = self.peek()!;
        if (next.type == EOF)
        {
            self.error = { .message = "Block not ended" };
            return PARSER_ERROR~;
        }

		if (self.current.type == NEW_LINE)
		{
			self.advance()!;
			continue;
		}

        Statement* statement = self.parse_statement(allow_return)!;
        block.push(statement);
    }

    self.advance()!;
    return block;
}

fn Statement*? Parser.parse_statement(&self, bool allow_return = false)
{
	Statement* result = mem::new(Statement);
    defer catch free(result);
	switch (self.current.type)
	{
		case VAR:
            *result = self.parse_statement_var()!;
			break;
        case IDENTIFIER:
            *result = self.parse_statement_identifier()!;
			break;
        case FN:
            *result = self.parse_statement_fn()!;
			break;
        case RETURN:
            if (!allow_return)
            {
                self.error = { .message = "Unexpected return statement encountered" };
                return PARSER_ERROR~;
            }

			Token next = self.peek()!;
			if (next.type == NEW_LINE || next.type == R_BRACE || next.type == EOF)
			{
            	self.advance()!;
				*result = { .kind = RETURN, .ret = { .expression = null } };
				break;
			}

            self.advance()!;
			*result = { .kind = RETURN, .ret = { .expression = self.parse_expression()! } };
			break;
		default:
			*result = { .kind = EXPRESSION, .exp = { .expression = self.parse_expression()! } };
			break;
	}

	return result;
}

fn Expression*? Parser.parse_expression(&self)
{
	Expression* left = self.parse_term()!;
    defer catch free_expression(left);

	while (self.current.type == PLUS || self.current.type == MINUS)
	{
		char op = self.current.value[0];
		self.advance()!;
		Expression* right = self.parse_term()!;

		Expression* node = mem::new(Expression);
		*node = { .kind = BINARY, .bin = { .left = left, .right = right, .operator = op } };
		left = node;
	}
	return left;
}

fn Expression*? Parser.parse_term(&self)
{
	Expression* left = self.parse_factor()!;
    defer catch free_expression(left);

	while (self.current.type == STAR || self.current.type == SLASH)
	{
		char op = self.current.value[0];
		self.advance()!;
		Expression* right = self.parse_factor()!;

		Expression* node = mem::new(Expression);
		*node = { .kind = BINARY, .bin = { .left = left, .right = right, .operator = op } };
		left = node;
	}
	return left;
}

fn Expression? Parser.parse_factor_call(&self)
{
    String fn_name = self.current.value;
    self.advance()!;
    self.advance()!;

    List {Expression*} parameters;
    parameters.init(mem);
    defer catch {
        foreach (expression : parameters) free_expression(expression);
        parameters.free();
    }

	uint parameter_count = 0;
    if (self.current.type == R_PAREN)
    {
		self.advance()!;
        return { .kind = CALL, .call = { .name = fn_name, .parameters = parameters, .parameter_count = parameter_count } };
    }

    while (self.current.type != R_PAREN)
    {
        Expression* exp = self.parse_expression()!;
		parameters.push(exp);
		parameter_count++;
		self.expect_any({ TokenType.COMMA, TokenType.R_PAREN }, "invalid fn call")!;
		if (self.current.type == COMMA)
		{
			self.advance()!;
		}
    }

	self.advance()!;
    return { .kind = CALL, .call = { .name = fn_name, .parameters = parameters, .parameter_count = parameter_count } };
}

fn Expression*? Parser.parse_factor(&self)
{
	switch (self.current.type)
	{
        case IDENTIFIER:
			Expression* node = mem::new(Expression);
            defer catch free(node);

            if (self.peek()!.type == L_PAREN) // call
            {
                *node = self.parse_factor_call()!;
                return node;
            }

			*node = { .kind = IDENTIFIER, .ident = { self.current.value } };
			self.advance()!;
			return node;
		case NUMBER:
			Expression* node = mem::new(Expression);
            defer catch free(node);
			*node = { .kind = NUMBER, .float_val = { String.to_float(self.current.value)!! } };
			self.advance()!;
			return node;
		case TRUE:
			nextcase;
		case FALSE:
			Expression* node = mem::new(Expression);
            defer catch free(node);
			*node = { .kind = BOOL, .bool_val = { self.current.type == TRUE } };
			self.advance()!;
			return node;
		case L_PAREN:
			self.advance()!;
			Expression* result = self.parse_expression()!;
            defer catch free_expression(result);
			if (self.current.type != R_PAREN)
			{
                self.error = { .message = "Missing closing parentheses" };
                return PARSER_ERROR~;
			}
			self.advance()!;
			return result;
		default:
            self.error = { .message = "Invalid token" };
            return PARSER_ERROR~;
	}
}
