module calc_comp;
import std::io;

enum TokenType : int {
    NUMBER,
    
    PLUS,
    MINUS,
    STAR,
    SLASH,

    L_PAREN,
    R_PAREN,

    ILLEGAL,
    EOF
}

struct Token {
    TokenType type;
    String value;
}

struct Lexer {
    String source;
    uint read_position;
    char current_char;
}

fn void Lexer.init(Lexer* this, String content) {
    *this = { .source = content, .read_position = 0, .current_char = 0 };
}

fn bool char.is_number(char* this) {
    return *this >= '0' && *this <= '9';
}

fn void Lexer.read_char(Lexer* this) {
    this.current_char = this.read_position >= this.source.len ? '\0' : this.source[this.read_position];
    this.read_position++;
}

fn Token Lexer.read_number(Lexer* this) {
    uint start = this.read_position - 1;
    bool read_dot = false;
    while (this.current_char.is_number() || this.current_char == '.') {
        if (this.current_char == '.') {
            if (read_dot) {
                io::printn("Invalid number");
                exit();
            }

            read_dot = true;
        }
        this.read_char();
    }

    return { .type = TokenType.NUMBER, .value = this.source[start .. this.read_position - 2] };
}

fn void Lexer.skip_whitespace(Lexer* this) {
    bool breakLoop = false;
    while (!breakLoop) {
        switch (this.current_char) {
            case ' ':
            case '\t':
            case '\n':
            case '\r':
                this.read_char();
                continue;
            default:
                breakLoop = true;
        }
    }
}

fn Token Lexer.next(Lexer* this) {
    Token token;
    if (this.current_char == '\0' && this.read_position == 0) {
        this.read_char();
    }

    this.skip_whitespace();

    switch(this.current_char) {
        case '(':
            token = { .type = TokenType.L_PAREN, .value = "(" };
            break;
        case ')':
            token = { .type = TokenType.R_PAREN, .value = ")" };
            break;
        case '+':
            token = { .type = TokenType.PLUS, .value = "+" };
            break;
        case '-':
            token = { .type = TokenType.MINUS, .value = "-" };
            break;
        case '*':
            token = { .type = TokenType.STAR, .value = "*" };
            break;
        case '/':
            token = { .type = TokenType.SLASH, .value = "/" };
            break;
        case '\0':
            token = { .type = TokenType.EOF, .value = "\0" };
            break;

        default:
            if (!this.current_char.is_number()) {
                token = { .type = TokenType.ILLEGAL, .value = {this.current_char} };
                break;
            }

            return this.read_number();
    }

    this.read_char();
    return token;
}
