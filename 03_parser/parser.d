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
    const(char)* name;
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
    import core.stdc.ctype : isdigit, isspace;
    import cl_getc : cl_getc, pos;

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

    fprintf(stderr, "unknown character: '%c' (at position %d)\n", prev, pos);
    assert(false);
}

///
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

///
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
