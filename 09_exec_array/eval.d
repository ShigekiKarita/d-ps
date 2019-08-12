module eval;

@nogc nothrow:

import stack : Stack;
import dict : Dict;
import vec: Vec;
import parser : Token;

/// Type tag for PSObject
enum PSType
{
    undefined,
    number,
    // executableName,
    // literalName,
    name,
    func,
    array
}

/// Value storage for PSObject
union PSValue
{
    @nogc nothrow:
    int number;
    string name;
    void function() func;
    Vec!PSObject array;
}

/// Dynamic type for PostScript
struct PSObject
{
    PSType type;
    PSValue value;

    void print()
    {
        import core.stdc.stdio : printf;

        with (PSType)
        final switch (type)
        {
        case undefined:
            printf("undefined");
            return;
        case number:
            printf("%d", value.number);
            return;
        case name:
            printf("%s", value.name.ptr);
            return;
        case func:
            printf("<builtin function>");
            return;
        case array:
            printf("<array>");
            return;
        }
    }
}

/// Global stack for eval()
Stack!PSObject globalStack;
Dict!(string, PSObject) globalNames;

/// Top level (global) data initialization
void initTopLevel()
{
    import builtin;

    // register builtin functions
    PSObject o;
    o.type = PSType.func;

    o.value.func = &defOp;
    globalNames.put("def", o);

    o.value.func = &addOp;
    globalNames.put("add", o);

    o.value.func = &subOp;
    globalNames.put("sub", o);

    o.value.func = &mulOp;
    globalNames.put("mul", o);

    o.value.func = &divOp;
    globalNames.put("div", o);
}

static this()
{
    initTopLevel();
}

/// Clear top level (global) data
void clearTopLevel()
{
    globalStack.length = 0;
    globalNames.length = 0;
}

/// Push an array object to globalStack
void pushExecArray(int* parserState)
{
    import parser : parseOne, Token, LexicalType;

    PSObject object;
    object.type = PSType.array;
    Token token;
    while (true)
    {
        *parserState = parseOne(&token, *parserState);
        assert(token.lexType != LexicalType.eof,
               "right brace (}) not found during parsing an array");
        if (token.lexType == LexicalType.rightBrace) break;
        if (pushOne(&token, parserState))
        {
            auto x = globalStack.pop();
            object.value.array.pushBack(x);
        }
    }
    globalStack.push(object);
}

/**
   Push one object to globalStack

   Params:
       token = start token for evaluation
       state = parser state

   Returns: true if and only if pushed
 */
bool pushOne(const Token* token, int* state)
{
    import core.stdc.stdio : fprintf, stderr;
    import parser : LexicalType;

    PSObject object;
    with (LexicalType)
    {
        switch (token.lexType)
        {
        case space:
            return false;
        case number:
            object.type = PSType.number;
            object.value.number = token.value.number;
            globalStack.push(object);
            return true;
        case executableName:
        case literalName:
            object.type = PSType.name;
            object.value.name = token.value.name;
            globalStack.push(object);
            return true;
        case leftBrace:
            pushExecArray(state);
            return true;
        default:
            fprintf(stderr, "unsupported token during parsing: %d\n", token.lexType);
            assert(false);
        }
    }
}

/// Parse the global input to the global stack for eval()
void pushInput()
{
    import core.stdc.stdio : fprintf, stderr;
    import parser : LexicalType, parseOne;

    Token token;
    with (LexicalType)
    {
        for (auto state = parseOne(&token); token.lexType != eof; state = parseOne(&token, state))
        {
            pushOne(&token, &state);
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
            case name:
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
    // push input tokens to stack
    pushInput();

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

/// test eval executable array of numbers
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("{123 456}");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.array);

    with (a.value.array)
    {
        assert(length == 2);
        assert(at(0).type == PSType.number);
        assert(at(0).value.number == 123);
        assert(at(1).type == PSType.number);
        assert(at(1).value.number == 456);
    }
}

/// test eval executable array like function
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("{123 add}");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.array);

    with (a.value.array)
    {
        assert(length == 2);
        assert(at(0).type == PSType.number);
        assert(at(0).value.number == 123);
        assert(at(1).type == PSType.name);
        assert(at(1).value.name == "add");
    }
}
