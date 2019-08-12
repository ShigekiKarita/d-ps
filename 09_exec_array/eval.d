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

    @nogc nothrow
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
            printf("{");
            foreach (i; 0 .. value.array.length)
            {
                value.array.at(i).print();
                if (i + 1 != value.array.length) printf(", ");
            }
            printf("}");
            return;
        }
    }
}

/// Global stack for eval()
Stack!PSObject globalStack;
Dict!(string, PSObject) globalNames;

void printGlobalStack()
{
    import core.stdc.stdio : printf;
    printf("[");
    foreach (i; 0 .. globalStack.length)
    {
        globalStack.payload[i].print();
        if (i + 1 != globalStack.length) printf(", ");
    }
    printf("]\n");
}

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
    initTopLevel();
}

/// Push an array object to globalStack
void pushArray(int* parserState)
{
    import parser : parseOne, Token, LexicalType;

    PSObject object;
    object.type = PSType.array;
    Token token;
    while (true)
    {
        // read next token
        *parserState = parseOne(&token, *parserState);
        assert(token.lexType != LexicalType.eof,
               "right brace (}) not found during parsing an array");

        // closed
        if (token.lexType == LexicalType.rightBrace) break;

        // push new item starts from the token that stored in globalStack
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
            pushArray(state);
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
        for (auto state = parseOne(&token);
             token.lexType != eof;
             state = parseOne(&token, state))
        {
            pushOne(&token, &state);
        }
    }
}

void execute(PSObject* object)
{
    import core.stdc.stdio : fprintf, stderr;

    with (PSType)
    {
        final switch (object.type)
        {
        case name:
            auto k = object.value.name;
            auto p = globalNames.get(k);
            if (p is null)
            {
                fprintf(stderr, "undefined name in eval(): %s\n", k.ptr);
                assert(false);
            }
            execute(p);
            return;
        case func:
            object.value.func();
            return;
        case array:
            with (object.value.array)
            {
                foreach (i; 0 .. length)
                {
                    auto o = at(i);
                    // execute(&o);
                    globalStack.push(o);
                }
            }
            executeStack();
            return;
        case number:
            globalStack.push(*object);
            return;
        case undefined:
            assert(false, "undefined found during execution");
        }
    }
}

/// Execute names in the global stack for eval()
void executeStack()
{
    if (globalStack.length > 0)
    {
        auto top = globalStack.pop();
        execute(&top);
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

/// test push some arrays
unittest
{
    import cl_getc : cl_getc_set_src;

    {
        cl_getc_set_src("{1}");
        pushInput();
        auto a = globalStack.pop();
        assert(a.type == PSType.array);
        with (a.value.array)
        {
            assert(length == 1);
            assert(at(0).type == PSType.number);
            assert(at(0).value.number == 1);
        }
        clearTopLevel();
    }
    {
        cl_getc_set_src("{/abc}");
        pushInput();
        auto a = globalStack.pop();
        assert(a.type == PSType.array);
        with (a.value.array)
        {
            assert(length == 1);
            assert(at(0).type == PSType.name);
            assert(at(0).value.name == "abc");
        }
        clearTopLevel();
    }
    {
        cl_getc_set_src("{abc}");
        pushInput();
        auto a = globalStack.pop();
        assert(a.type == PSType.array);
        with (a.value.array)
        {
            assert(length == 1);
            assert(at(0).type == PSType.name);
            assert(at(0).value.name == "abc");
        }
        clearTopLevel();
    }
    {
        cl_getc_set_src("{1 2}");
        pushInput();
        auto a = globalStack.pop();
        assert(a.type == PSType.array);
        with (a.value.array)
        {
            assert(length == 2);
            assert(at(0).type == PSType.number);
            assert(at(0).value.number == 1);
            assert(at(1).type == PSType.number);
            assert(at(1).value.number == 2);
        }
        clearTopLevel();
    }
    {
        cl_getc_set_src("{1} {2}");
        pushInput();
        auto a = globalStack.pop();
        assert(a.type == PSType.array);
        with (a.value.array)
        {
            assert(length == 1);
            assert(at(0).type == PSType.number);
            assert(at(0).value.number == 2);
        }
        a = globalStack.pop();
        assert(a.type == PSType.array);
        with (a.value.array)
        {
            assert(length == 1);
            assert(at(0).type == PSType.number);
            assert(at(0).value.number == 1);
        }
        clearTopLevel();
    }
    {
        cl_getc_set_src("{1 {2} 3}");
        pushInput();
        auto a = globalStack.pop();
        assert(a.type == PSType.array);
        with (a.value.array)
        {
            assert(length == 3);
            assert(at(0).type == PSType.number);
            assert(at(0).value.number == 1);
            assert(at(1).type == PSType.array);
            assert(at(1).value.array.length == 1);
            assert(at(1).value.array.at(0).type == PSType.number);
            assert(at(1).value.array.at(0).value.number == 2);
            assert(at(2).type == PSType.number);
            assert(at(2).value.number == 3);
        }
        clearTopLevel();
    }
    // {
    //     cl_getc_set_src("{123 add}");
    //     eval();
    //     auto a = globalStack.pop();
    //     assert(a.type == PSType.array);

    //     with (a.value.array)
    //     {
    //         assert(length == 2);
    //         assert(at(0).type == PSType.number);
    //         assert(at(0).value.number == 123);
    //         assert(at(1).type == PSType.name);
    //         assert(at(1).value.name == "add");
    //     }
    //     clearTopLevel();
    // }
}

/// test eval executable nested array
unittest
{
    import core.stdc.stdio : printf;
    import cl_getc : cl_getc_set_src;

    {
        cl_getc_set_src("/addone {1 add} def");
        eval();
        cl_getc_set_src("2 addone");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 2 + 1);
        clearTopLevel();
    }

    {
        cl_getc_set_src("/one {1} def");
        eval();
        cl_getc_set_src("/onetwo {one 2} def");
        eval();
        cl_getc_set_src("onetwo add");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 2 + 1);
        clearTopLevel();
    }

    {
        cl_getc_set_src("/abc {1 2 add} def");
        eval();
        cl_getc_set_src("abc");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 2 + 1);
        clearTopLevel();
    }

    {
        cl_getc_set_src("/ZZ {6} def");
        eval();
        cl_getc_set_src("/YY {4 5 ZZ} def");
        eval();
        cl_getc_set_src("/XX {1 2 3 YY 7} def");
        eval();
        cl_getc_set_src("XX");
        eval();
        foreach_reverse (i; 1 .. 8)
        {
            auto x = globalStack.pop();
            executeStack();
            assert(x.type == PSType.number);
            assert(x.value.number == i);
        }
        clearTopLevel();
    }
}
