module calc_comp;

// Expressions

enum ExpressionKind : short
{
	NUMBER,
	BINARY,
	IDENTIFIER	
}

struct NumberExpression
{
	float number;
}

struct IdentifierExpression
{
	String identifier;
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
		IdentifierExpression ident;
	}
}

// Statements

enum StatementKind : short
{
	VAR_DECLARATION,
	EXPRESSION
}

struct VarDeclarationStatement
{
	String name;
	Expression* rhs_expression;
}

struct ExpressionStatement
{
	Expression* expression;
}

struct Statement
{
	StatementKind kind;
	union
	{
		VarDeclarationStatement var_dec;
		ExpressionStatement exp;
	}
}