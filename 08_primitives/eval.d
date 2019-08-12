module eval;

@nogc nothrow:

import stack : Stack;
import dict : Dict;

/// Type tag for PSObject
enum PSType
{
    undefined,
    number,
    executableName,
    literalName,
    func
}

/// Value storage for PSObject
union PSValue
{
    @nogc nothrow:
    int number;
    string name;
    void function() func;
}

/// Dynamic type for PostScript
struct PSObject
{
    PSType type;
    PSValue value;
}

/// Global stack for eval()
Stack!PSObject globalStack;
Dict!(string, PSObject) globalNames;

/// Global initialization
static this()
{
    import builtin;

    // register builtin functions
    PSObject o;
    o.type = PSType.func;

    o.value.func = &addOp;
    globalNames.put("add", o);

    o.value.func = &defOp;
    globalNames.put("def", o);
}

/// Clear top level (global) data
void clearTopLevel()
{
    globalStack.length = 0;
    globalNames.length = 0;
}

/// Parse the global input to the global stack for eval()
void parseInput()
{
    import core.stdc.stdio : fprintf, stderr;
    import parser : parseOne, Token, LexicalType;

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
                object.type = PSType.executableName;
                object.value.name = token.value.name;
                globalStack.push(object);
                break;
            case literalName:
                object.type = PSType.literalName;
                object.value.name = token.value.name;
                globalStack.push(object);
                break;
            default:
                fprintf(stderr, "unsupported type for eval(): %d\n", token.lexType);
                assert(false);
            }
        }
    }
}


/// Execute names in the global stack for eval()
void executeStack()
{
    import core.stdc.stdio : fprintf, stderr;

    bool end = false;
    while (globalStack.length > 1 && !end)
    {
        auto top = globalStack.pop();
        with (PSType)
        {
            switch (top.type)
            {
            case executableName:
                auto name = top.value.name;
                auto object = globalNames.get(name);
                if (object is null)
                {
                    fprintf(stderr, "undefined name in eval(): %s\n", top.value.name.ptr);
                    assert(false);
                }
                else if (object.type == func)
                {
                    object.value.func();
                }
                else
                {
                    globalStack.push(*object);
                }
                break;
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
}

/// evaluate input string on the globalStack
void eval()
{
    // parse input and push tokens to stack
    parseInput();

    // pop stack with executable
    executeStack();
}

/// test eval one number
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

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

    scope (exit) clearTopLevel();

    cl_getc_set_src("123 456");
    eval();
    auto a = globalStack.pop();
    auto b = globalStack.pop();

    assert(a.type == PSType.number);
    assert(a.value.number == 456);
    assert(b.type == PSType.number);
    assert(b.value.number == 123);
}

/// test eval add two numbers
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("123 456 add");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.number);
    assert(a.value.number == 123 + 456);
}

/// test eval nested add
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("1 2 3 add add 4 5 6 7 8 9 add add add add add add"); // 1 2 3 add add");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.number);
    assert(a.value.number == 45);
}

/// test eval def
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("/abc 12 def");
    eval();
    auto abc = globalNames.get("abc");
    assert(abc.type == PSType.number);
    assert(abc.value.number == 12);

    cl_getc_set_src("1 abc add");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.number);
    assert(a.value.number == 1 + 12);
}
