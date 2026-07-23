module calc_comp;
import std::collections::map;
import std::io;

struct Environment
{
	Allocator allocator;
	map::HashMap {String, float} variables;
	map::HashMap {String, FnDeclarationStatement*} functions;
	Environment* parent;
}

struct FnDeclarationWithScope
{
	FnDeclarationStatement* declaration;
	Environment* scope;
}

fn Environment* Environment.init(&self, Allocator allocator, Environment* parent = null)
{
	self.allocator = allocator;
	self.variables.init(allocator);
	self.functions.init(allocator);
	self.parent = parent;
	return self;
}

fn void Environment.free(&self)
{
	self.variables.free();
	self.functions.free();
}

fn FnDeclarationWithScope? Environment.lookup_fn(&self, String name)
{
	if (self.functions.has_key(name))
	{
		return { .declaration = self.functions.get(name)!, .scope = self };
	}

	if (self.variables.has_key(name))
	{
		io::printfn("'%s' is not a function", name);
		return RUNTIME_ERROR~;
	}

	if (self.parent == null)
	{
		io::printfn("Undefined reference: '%s'", name);
		return RUNTIME_ERROR~;
	}

	return self.parent.lookup_fn(name)!;
}

fn float? Environment.lookup_var(&self, String name)
{
	if (self.variables.has_key(name))
	{
		return self.variables.get(name)!;
	}

	if (self.functions.has_key(name))
	{
		io::printfn("'%s' is not a variable", name);
		return RUNTIME_ERROR~;
	}

	if (self.parent == null)
	{
		io::printfn("Undefined reference: %s", name);
		return RUNTIME_ERROR~;
	}

	return self.parent.lookup_var(name)!;
}

fn void? Environment.declare_fn(&self, FnDeclarationStatement* declaration)
{
	if (self.variables.has_key(declaration.name) || self.functions.has_key(declaration.name))
	{
		io::printfn("Name already defined: %s", declaration.name);
		return RUNTIME_ERROR~;
	}

	self.functions.set(declaration.name, declaration);
}

fn void? Environment.declare_var(&self, String name, float value)
{
	if (self.variables.has_key(name) || self.functions.has_key(name))
	{
		io::printfn("Name already defined: %s", name);
		return RUNTIME_ERROR~;
	}

	self.variables.set(name, value);
}

fn void? Environment.assign_var(&self, String name, float value)
{
	if (self.functions.has_key(name))
	{
		io::printfn("%s is not a variable", name);
		return RUNTIME_ERROR~;
	}

	if (self.variables.has_key(name))
	{
		self.variables.set(name, value);
		return;
	}

	if (self.parent == null)
	{
		io::printfn("Undefined reference: %s", name);
		return RUNTIME_ERROR~;
	}

	return self.parent.assign_var(name, value);
}