module calc_comp;
import std::io;

fn int main(String[] args)
{
	if (args.len < 2)
	{
		io::printfn("File path must be provided");
		return 1;
	}

    char[] buffer = mem::new_array(char, 2048);
	defer free(buffer);

	char[]? content = read_file(args[1], buffer);
	if (catch excuse = content)
	{
		io::printfn("Failed to read file: %s", excuse);
		return 1;
	}

	Lexer lexer;
	lexer.init((String)buffer);
	Parser parser;
	parser.init(&lexer);

    Program program = parser.parse_program();
    defer free_program(&program);
    eval_program(&program);

	return 0;
}
