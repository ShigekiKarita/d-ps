module eval;

import stack : Stack;


enum PSType
{
    number,
    name
}

union PSValue
{
    int number;
    string name;
}

struct PSObject
{
    PSType type;
    PSValue value;
}

Stack!PSObject globalStack;

/// evaluate input string on the globalStack
void eval()
{
    import parser : parseOne, Token, LexicalType;

    // push tokens to stack
    Token token;
    with (LexicalType)
    {
        for (auto state = parseOne(&token); token.lexType != eof; state = parseOne(&token, state))
        {
            PSObject object;
            switch (token.lexType)
            {
                case space:
                    break;
                case number:
                    object.type = PSType.number;
                    object.value.number = token.value.number;
                    break;
                case executableName:
                case literalName:
                    object.type = PSType.name;
                    object.value.name = token.value.name;
                    break;
                default:
                    import core.stdc.stdio : fprintf, stderr;
                    fprintf(stderr, "unsupported type for eval(): %d\n", token.lexType);
                    assert(false);
            }
            globalStack.push(object);
        }
    }

    // pop stack
}


unittest
{
    import cl_getc : cl_getc_set_src;
    cl_getc_set_src("123");

    eval();
    auto item = globalStack.pop();
    assert(item.type == PSType.number);
    assert(item.value.number == 123);
}
