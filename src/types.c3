module calc_comp;

enum Type : uint
{
	VOID,
	FLOAT,
	BOOL
}

struct Value
{
	Type type;
	union
	{
		bool bool_val;
		float float_val;
	}
}

struct NameTypePair
{ 
	String name;
	Type type;
}

fn uint NameTypePair.hash(&self)
{
	return self.name.hash() + self.type.ordinal;
}