module builtin;

@nogc nothrow:

import eval : eval, executeStack, globalNames, globalStack, PSObject, PSType, clearTopLevel;

/// builtin def function
void defOp()
{
    // get args
    // executeStack();
    auto a = globalStack.pop();

    // executeStack();
    auto b = globalStack.pop();
    assert(b.type == PSType.name, "1st arg of add should be literal name: e.g., /foo 1 def");

    // put name into global dict
    globalNames.put(b.value.name, a);

    // NOTE: rethinking return value?
    // globalStack.push(a);
}

/// test eval def
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("/abc 12 def");
    eval();
    auto abc = globalNames.get("abc");
    assert(abc);
    assert(abc.type == PSType.number);
    assert(abc.value.number == 12);

    cl_getc_set_src("1 abc add");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.number);
    assert(a.value.number == 1 + 12);

    cl_getc_set_src("abc");
    eval();
    auto b = globalStack.pop();
    assert(b.type == PSType.number);
    assert(b.value.number == 12);
}

/// builtin add function
void addOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop();
    assert(a.type == PSType.number, "1st arg of `add` should be number");

    executeStack();
    auto b = globalStack.pop();
    assert(b.type == PSType.number, "2nd arg of `add` should be number");

    // set return value
    PSObject ret;
    ret.type = PSType.number;
    ret.value.number = a.value.number + b.value.number;
    globalStack.push(ret);
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

/// builtin sub function
void subOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop();
    assert(a.type == PSType.number, "1st arg of `sub` should be number");

    executeStack();
    auto b = globalStack.pop();
    assert(b.type == PSType.number, "2nd arg of `sub` should be number");

    // set return value
    PSObject ret;
    ret.type = PSType.number;
    ret.value.number = b.value.number - a.value.number;
    globalStack.push(ret);
}

/// test eval sub two numbers
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("5 3 sub");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.number);
    assert(a.value.number == 5 - 3);
}

/// builtin mul function
void mulOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop();
    assert(a.type == PSType.number, "1st arg of `mul` should be number");

    executeStack();
    auto b = globalStack.pop();
    assert(b.type == PSType.number, "2nd arg of `mul` should be number");

    // set return value
    PSObject ret;
    ret.type = PSType.number;
    ret.value.number = b.value.number * a.value.number;
    globalStack.push(ret);
}

/// test eval mul two numbers
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("5 3 mul");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.number);
    assert(a.value.number == 5 * 3);
}

/// builtin div function
void divOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop();
    assert(a.type == PSType.number, "1st arg of `div` should be number");

    executeStack();
    auto b = globalStack.pop();
    assert(b.type == PSType.number, "2nd arg of `div` should be number");

    // set return value
    PSObject ret;
    ret.type = PSType.number;
    ret.value.number = b.value.number / a.value.number;
    globalStack.push(ret);
}

/// test eval div two numbers
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    cl_getc_set_src("7 3 div");
    eval();
    auto a = globalStack.pop();
    assert(a.type == PSType.number);
    assert(a.value.number == 7 / 3);
}
