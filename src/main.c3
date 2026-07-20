module calc_comp;
import std::collections::map;
import std::io;
import libc;

fn void run_repl() @noreturn
{
    Environment* env = mem::new(Environment);
    defer free(env);

    env = env.init(mem);
    defer env.free();

    while(true)
    {
        io::printf("|> ");
        @pool()
        {
            String? line = io::treadline();
            if (catch excuse = line)
            {
                if (excuse == io::EOF)
                {
                    io::printn("\nExiting...");
                    libc::exit(0);
                }
                io::printn("Failed to read line");
                continue;
            }

        	Lexer lexer;
	        lexer.init(line);
	        Parser parser;
	        if (catch excuse = parser.init(&lexer))
            {
                io::printn(parser.error.message);
                continue;
            }

            Statement*? statement = parser.parse_statement();
            if (catch excuse = statement)
            {
                io::printn(parser.error.message);
                continue;
            }

            defer free_statement(statement);

            if (catch excuse = eval_statement(statement, env))
            {
                // TODO: Verify this
                continue;
            }
        };
    }
}

fn int main(String[] args)
{
	if (args.len < 2)
	{
        run_repl();
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
	if (catch excuse = parser.init(&lexer))
    {
        io::printn(parser.error.message);
        return 1;
    }

    Program? program = parser.parse_program();
	if (catch excuse = program)
    {
        io::printn(parser.error.message);
        return 1;
    }

    defer free_program(&program);
    if (catch excuse = eval_program(&program))
    {
        return 1;
    }

	return 0;
}
