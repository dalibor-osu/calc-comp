module calc_comp;
import std::io;
import libc;

fn void exit(int status = 1) @noreturn {
    libc::exit(status);
}

fn bool char.is_number(char* this) {
    return *this >= '0' && *this <= '9';
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
