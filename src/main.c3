module calc_comp;
import std::io;
import libc;

fn void exit(int status = 1) @noreturn {
    libc::exit(status);
}

// https://c3-lang.org/language-common/optionals-advanced/#file-reading-example
<*
 Function modifies 'buffer'
 Returns an Optional with a 'char[]' result
 OR an empty Optional with an Excuse
*>
fn char[]? read_file(String filename, char[] buffer)
{
    File file = file::open(filename, "r")!;
    defer (void)file.close();

    file.read(buffer)!;

    return buffer;
}

fn void print_expression(Expression* exp) {
    switch (exp.kind) {
        case NUMBER:
            io::printf("%f", exp.num.number);
            break;
        case BINARY:
            io::printf("(");
            print_expression(exp.bin.left);
            io::printf(" %c ", exp.bin.operator);
            print_expression(exp.bin.right);
            io::printf(")");
            break;
        default:
            io::printfn("Invalid expression kind");
            exit();
    }
}

fn void free_expression(Expression* exp) {
    if (exp.kind == ExpressionKind.BINARY) {
        free_expression(exp.bin.left);
        free_expression(exp.bin.right);
    }
    free(exp);
}

fn float eval_binary(BinaryExpression* binExp) {
    switch(binExp.operator) {
        case '+': return eval(binExp.left) + eval(binExp.right);
        case '-': return eval(binExp.left) - eval(binExp.right);
        case '*': return eval(binExp.left) * eval(binExp.right);
        case '/': return eval(binExp.left) / eval(binExp.right);
        default:
            io::printn("Invalid operator");
            exit();
    }
}

fn float eval(Expression* exp) {
    switch (exp.kind) {
        case NUMBER:
            return exp.num.number;
        case BINARY:
            return eval_binary(&exp.bin);
        default:
            io::printfn("Invalid expression kind");
            exit();
    }
}

fn int main(String[] args)
{
    if (args.len < 2) {
        io::printfn("File path must be provided");
        return 1;
    }

    char[] buffer = mem::new_array(char, 2048);
    defer free(buffer);

    char[]? content = read_file(args[1], buffer);
    if (catch excuse = content) {
        io::printfn("Failed to read file: %s", excuse);
        return 1;
    }
    
    Lexer lexer = { .source = (String)buffer, .read_position = 0, .current_char = 0 };
    Parser parser = { .lexer = &lexer };
    parser.advance();
    Expression* exp = parser.parse_expression();
    print_expression(exp);
    io::printn();

    io::printfn("Result: %f", eval(exp));

    free_expression(exp);

    return 0;
}
