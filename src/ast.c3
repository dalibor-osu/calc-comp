module calc_comp;
import std::collections::list;

// Expressions

enum ExpressionKind : short
{
	NUMBER,
	BINARY,
	IDENTIFIER,
    CALL
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

struct IdentifierExpression
{
	String identifier;
}

struct CallExpression
{
	String name;
    List {Expression*} args;
}

struct Expression
{
	ExpressionKind kind;
	union
	{
		NumberExpression num;
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
	Expression* rhs_expression;
}

struct FnDeclarationStatement
{
	String name;
	List {String} parameter_names;
    List {Statement} body;
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
