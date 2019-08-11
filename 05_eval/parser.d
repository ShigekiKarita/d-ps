module parser;

@nogc nothrow:

import core.stdc.stdio;

enum LexicalType
{
    undefined,
    eof,
    space,
    number,         // 0, 1, -1, ...
    leftBrace,      // {
    rightBrace,     // }
    executableName, // abc, hello, ...
    literalName,    // /abc, /hello, ...
}

union TokenValue
{
    int number;
    int onechar;
    string name;
}

struct Token
{
    LexicalType lexType;
    TokenValue value;
}

/**
   Parse one token

   Params:
       result = is a parsed token
   Returns:
       last consumed character
 */
int parseOne(Token* result)
{
    import cl_getc : cl_getc;
    auto prev = cl_getc();
    return parseOne(result, prev);
}

/**
   Parse one token

   Params:
       result = is a parsed token
       prev = a previous character
   Returns:
       last consumed character
 */
int parseOne(Token* result, int prev)
{
    import core.stdc.stdio : fprintf, stderr;
    import core.stdc.ctype : isdigit, isspace, isalpha, isgraph;
    import cl_getc : cl_getc, pos, input;

    // parse nothing
    if (prev == EOF)
    {
        result.lexType = LexicalType.eof;
        prev = cl_getc();
        return prev;
    }
    // parse space
    else if (isspace(prev))
    {
        result.lexType = LexicalType.space;
        // consume subsequent spaces
        while (isspace(prev))
        {
            prev = cl_getc();
        }
        return prev;
    }
    // parse number
    else if (isdigit(prev))
    {
        result.lexType = LexicalType.number;
        result.value.number = 0;
        while (isdigit(prev))
        {
            result.value.number = 10 * result.value.number + (prev - '0');
            prev = cl_getc();
        }
        return prev;
    }
    // parse left/right braces
    else if (prev == '{')
    {
        result.lexType = LexicalType.leftBrace;
        result.value.onechar = prev;
        prev = cl_getc();
        return prev;
    }
    else if (prev == '}')
    {
        result.lexType = LexicalType.rightBrace;
        result.value.onechar = prev;
        prev = cl_getc();
        return prev;
    }
    // parse executable/literal name
    else if (isalpha(prev) || prev == '/')
    {
        import core.stdc.stdlib : malloc;
        import core.stdc.string : strncpy;
        result.lexType = prev == '/'
                         ? LexicalType.literalName
                         : LexicalType.executableName;
        const s = input + pos - 1;
        size_t n = 1;
        while (isgraph(prev))
        {
            prev = cl_getc();
            ++n;
        }
        auto p = cast(char*) malloc(char.sizeof * n);
        strncpy(p, s, n);
        p[n] = 0;
        result.value.name = cast(string) p[0 .. n - 1];
        return prev;
    }

    fprintf(stderr, "unknown character: '%c' (at position %d of the input '%s')\n", prev, pos, input);
    assert(false);
}

/// test parse numbers
unittest
{
    import cl_getc : cl_getc_set_src;

    Token token;
    cl_getc_set_src("123  345");
    auto prev = parseOne(&token);
    assert(prev == ' ');
    assert(token.lexType == LexicalType.number);
    assert(token.value.number == 123);

    prev = parseOne(&token, prev);
    assert(prev == '3');
    assert(token.lexType == LexicalType.space);

    prev = parseOne(&token, prev);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.number);
    assert(token.value.number == 345);

    prev = parseOne(&token, prev);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.eof);
}

/// test parse an executable name
unittest
{
    import cl_getc : cl_getc_set_src;

    Token token;
    cl_getc_set_src("add_ 123");
    auto prev = parseOne(&token);
    assert(prev == ' ');
    assert(token.lexType == LexicalType.executableName);
    assert(token.value.name == "add_");

    prev = parseOne(&token, prev);
    assert(prev == '1');
    assert(token.lexType == LexicalType.space);

    prev = parseOne(&token, prev);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.number);
    assert(token.value.number == 123);

    prev = parseOne(&token, prev);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.eof);
}

/// test parse a literal name
unittest
{
    import cl_getc : cl_getc_set_src;

    Token token;
    cl_getc_set_src("/add_ 123");
    auto prev = parseOne(&token);
    assert(prev == ' ');
    assert(token.lexType == LexicalType.literalName);
    assert(token.value.name == "/add_");

    prev = parseOne(&token, prev);
    assert(prev == '1');
    assert(token.lexType == LexicalType.space);

    prev = parseOne(&token, prev);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.number);
    assert(token.value.number == 123);

    prev = parseOne(&token, prev);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.eof);
}

/// test parse braces
unittest
{
    import cl_getc : cl_getc_set_src;

    Token token;
    cl_getc_set_src("{}");
    auto prev = parseOne(&token);
    assert(prev == '}');
    assert(token.lexType == LexicalType.leftBrace);

    prev = parseOne(&token, prev);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.rightBrace);

    prev = parseOne(&token, prev);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.eof);
}



void parser_print_all() {
    int ch = EOF;
    Token token;
    do
    {
        ch = parseOne(&token, ch);
        if (token.lexType != LexicalType.undefined)
        {
            with (LexicalType)
                switch(token.lexType)
                {
                    case number:
                        printf("num: %d\n", token.value.number);
                        break;
                    case space:
                        printf("space!\n");
                        break;
                    case leftBrace:
                        printf("Open curly brace '%c'\n", token.value.onechar);
                        break;
                    case rightBrace:
                        printf("Close curly brace '%c'\n", token.value.onechar);
                        break;
                    case executableName:
                        printf("EXECUTABLE_NAME: %s\n", token.value.name.ptr);
                        break;
                    case literalName:
                        printf("LITERAL_NAME: %s\n", token.value.name.ptr);
                        break;
                    default:
                        static foreach (s; __traits(allMembers, LexicalType))
                        {
                            {
                                mixin("auto b = token.lexType == " ~ s ~ ";");
                                if (b)
                                    printf("Unknown type %s.%s\n", LexicalType.stringof.ptr, s.ptr);
                            }
                        }
                        break;
                }
        }
    }
    while(ch != EOF);
}
