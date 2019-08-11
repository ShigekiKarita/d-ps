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
    int number = 0;
    char onechar;
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
    // parse executable name
    else if (isalpha(prev))
    {
        import core.stdc.stdlib : malloc;
        import core.stdc.string : strncpy;
        result.lexType = LexicalType.executableName;
        const s = input + pos - 1;
        size_t n = 1;
        while (isgraph(prev))
        {
            prev = cl_getc();
            ++n;
        }
        auto p = cast(char*) malloc(char.sizeof * n);
        strncpy(p, s, n);
        result.value.name = cast(string) p[0 .. n - 1];
        return prev;
    }

    fprintf(stderr, "unknown character: '%c' (at position %d of the input '%s')\n", prev, pos, input);
    assert(false);
}

/// test parse one number
unittest
{
    import cl_getc : cl_getc_set_src;

    Token token;
    cl_getc_set_src("123");
    auto prev = parseOne(&token);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.number);
    assert(token.value.number == 123);
}

/// test parse two numbers and one space
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
}

/// test parse an executable name
unittest
{
    import cl_getc : cl_getc_set_src;

    Token token;
    cl_getc_set_src("add_");
    auto prev = parseOne(&token);
    assert(prev == EOF);
    assert(token.lexType == LexicalType.executableName);
    assert(token.value.name == "add_");
}
