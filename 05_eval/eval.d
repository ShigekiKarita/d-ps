module eval;

import stack : Stack;


enum PSType
{
    undefined,
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
    import core.stdc.stdio : fprintf, stderr;

    // reset stack
    globalStack.length = 0;

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
                    globalStack.push(object);
                    break;
                case executableName:
                case literalName:
                    object.type = PSType.name;
                    object.value.name = token.value.name;
                    globalStack.push(object);
                    break;
                default:
                    fprintf(stderr, "unsupported type for eval(): %d\n", token.lexType);
                    assert(false);
            }
        }
        assert(token.lexType == eof);
    }
    /*
    // pop stack with executable
    bool end = false;
    while (globalStack.length > 1 && !end)
    {
        auto top = globalStack.pop();
        with (PSType)
        {
            switch (top.type)
            {
                case name:
                    if (top.value.name == "add")
                    {
                        // get args
                        auto a = globalStack.pop();
                        assert(a.type == number, "1st arg of add should be number");
                        auto b = globalStack.pop();
                        assert(b.type == number, "2nd arg of add should be number");
                        // set return value
                        PSObject ret;
                        ret.type = number;
                        ret.value.number = a.value.number + b.value.number;
                        globalStack.push(ret);
                        break;
                    }
                    goto default;
                case number:
                    globalStack.push(top);
                    end = true;
                    break;
                default:
                    fprintf(stderr, "unsupported type for eval(): %d\n", top.type);
                    assert(false);
            }
        }
    }
    */
}

/// test eval one number
unittest
{
    import cl_getc : cl_getc_set_src;

    cl_getc_set_src("123");
    eval();
    auto top = globalStack.pop();
    assert(top.type == PSType.number);
    assert(top.value.number == 123);
}

/// test eval two numbers
unittest
{
    import cl_getc : cl_getc_set_src;

    cl_getc_set_src("123 456");
    eval();
    auto a = globalStack.pop();
    auto b = globalStack.pop();

    assert(a.type == PSType.number);
    assert(a.value.number == 456);
    assert(b.type == PSType.number);
    assert(b.value.number == 123);
}
