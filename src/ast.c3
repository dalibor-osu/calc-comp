module calc_comp;
import std::collections::list;

// Expressions

enum ExpressionKind : short
{
	NUMBER,
	BOOL,
	BINARY,
	IDENTIFIER,
    CALL
}

struct FloatExpression
{
	float value;
}

struct BoolExpression
{
	bool value;
}

struct BinaryExpression
{
	Expression* left;
	Expression* right;
	char operator;
}

struct IdentifierExpression
{
	String identifier;
}

struct CallExpression
{
	String name;
    List {Expression*} parameters;
	uint parameter_count;
}

struct Expression
{
	ExpressionKind kind;
	union
	{
		FloatExpression float_val;
		BoolExpression bool_val;
		BinaryExpression bin;
		IdentifierExpression ident;
        CallExpression call;
	}
}

// Statements

enum StatementKind : short
{
	VAR_DECLARATION,
    FN_DECLARATION,
    VAR_ASSIGN,
	EXPRESSION,
    RETURN
}

struct VarDeclarationStatement
{
	String name;
	Type type;
	Expression* rhs_expression;
}

struct FnDeclarationStatement
{
	String name;
	List {NameTypePair} parameters;
	uint parameter_count;
	Type return_type;
    List {Statement*} body;
}

struct VarAssignStatement
{
	String name;
	Expression* rhs_expression;
}

struct ExpressionStatement
{
	Expression* expression;
}

struct ReturnStatement
{
	Expression* expression;
}

struct Statement
{
	StatementKind kind;
	union
	{
		VarDeclarationStatement var_dec;
		FnDeclarationStatement fn_dec;
        VarAssignStatement var_assign;
		ExpressionStatement exp;
        ReturnStatement ret;
	}
}
