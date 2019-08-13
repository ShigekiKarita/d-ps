module builtin;

@nogc nothrow:

import eval : eval, executeStack, globalNames, globalStack, PSObject, PSType, clearTopLevel;

void registerBuiltinOps()
{
    // register builtin functions
    PSObject o;
    o.type = PSType.func;

    // special ops
    o.value.func = &defOp;
    globalNames.put("def", o);

    o.value.func = &ifelseOp;
    globalNames.put("ifelse", o);

    o.value.func = &ifOp;
    globalNames.put("if", o);

    o.value.func = &repeatOp;
    globalNames.put("repeat", o);

    o.value.func = &whileOp;
    globalNames.put("while", o);

    // stack ops
    o.value.func = &popOp;
    globalNames.put("pop", o);

    o.value.func = &exchOp;
    globalNames.put("exch", o);

    o.value.func = &dupOp;
    globalNames.put("dup", o);

    o.value.func = &indexOp;
    globalNames.put("index", o);

    o.value.func = &rollOp;
    globalNames.put("roll", o);

    // numerical ops
    o.value.func = &binaryOp!"+";
    globalNames.put("add", o);

    o.value.func = &binaryOp!"-";
    globalNames.put("sub", o);

    o.value.func = &binaryOp!"*";
    globalNames.put("mul", o);

    o.value.func = &binaryOp!"/";
    globalNames.put("div", o);

    // logical ops
    o.value.func = &binaryOp!"==";
    globalNames.put("eq", o);

    o.value.func = &binaryOp!"!=";
    globalNames.put("neq", o);

    o.value.func = &binaryOp!">";
    globalNames.put("gt", o);

    o.value.func = &binaryOp!">=";
    globalNames.put("ge", o);

    o.value.func = &binaryOp!"<";
    globalNames.put("lt", o);

    o.value.func = &binaryOp!"<=";
    globalNames.put("le", o);
}

/*****************
 special operators
 *****************/

/// builtin def function
void defOp()
{
    // NOTE: do not executeStack because it is lazy binding
    // get args
    auto a = globalStack.pop();
    auto b = globalStack.pop();
    assert(b.type == PSType.name, "1st arg of add should be literal name: e.g., /foo 1 def");

    // put name into global dict
    globalNames.put(b.value.name, a);
    // NOTE: push nothing?
    // globalStack.push(a);
}

///
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

/// builtin ifelse function
void ifelseOp()
{
    import eval : execute, executeStack;

    auto a = globalStack.pop();
    auto b = globalStack.pop();
    executeStack();
    auto cond = globalStack.pop();
    auto ret = (cond.type == PSType.number && cond.value.number == 0) ? a : b;
    execute(&ret);
}

///
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("0 1 {1 add} {2 add} ifelse");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 1);
    }
    {
        cl_getc_set_src("1 1 {1 add} {2 add} ifelse");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 2);
    }
    {
        cl_getc_set_src("/abc 0 def");
        eval();
        cl_getc_set_src("0 abc {1 add} {2 add} ifelse");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 2);
    }
    {
        cl_getc_set_src("/abc 1 def");
        eval();
        cl_getc_set_src("0 abc {1 add} {2 add} ifelse");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 1);
    }
}

/// builtin ifelse function
void ifOp()
{
    import eval : execute, executeStack;

    auto a = globalStack.pop();
    executeStack();
    auto cond = globalStack.pop();
    if (!(cond.type == PSType.number && cond.value.number == 0))
    {
        execute(&a);
    }
}

///
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("0 1 {1 add} if");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 1);
    }
    {
        cl_getc_set_src("0 0 {1 add} if");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 0);
    }
}

/// builtin repeat function
void repeatOp()
{
    import eval : execute, executeStack;

    auto proc = globalStack.pop();
    executeStack();
    auto n = globalStack.pop();
    assert(n.type == PSType.number, "2nd arg of repeat should be number, e.g., n proc repeat");
    foreach (_; 0 .. n.value.number)
    {
        execute(&proc);
    }
}

///
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("/abc 0 def");
        eval();
        cl_getc_set_src("1 2 {dup} repeat");
        eval();
        assert(globalStack.length == 1 + 2);
        foreach (i; 0 .. 3)
        {
            auto top = globalStack.pop();
            assert(top.type == PSType.number);
            assert(top.value.number == 1);
        }
    }
}


/// builtin while
void whileOp()
{
    import eval : execute;

    while (true)
    {
        auto a = globalStack.pop();
        execute(&a);
        auto top = globalStack.top;

        if (top is null) return;
        if (top.type == PSType.number && top.value.number == 0) return;

        auto b = globalStack.pop();
        execute(&b);
    }
}

/// test eval while
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("/abc 1 def");
        eval();
        cl_getc_set_src("{abc} {/abc 0 def} while");
        eval();
        auto top = globalStack.pop();
        assert(top.type == PSType.number);
        assert(top.value.number == 0);
    }
}

/***************
 stack operators
 ***************/

/// builtin stack pop: any1 ->
void popOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop(); // discard
}

///
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("1 2 pop");
        eval();
        auto top = globalStack.top();
        assert(top.type == PSType.number);
        assert(top.value.number == 1);

        cl_getc_set_src("pop");
        eval();
        assert(globalStack.empty);
    }
}

/// builtin stack exchange: any1 any2 -> any2 any1
void exchOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop();
    executeStack();
    auto b = globalStack.pop();

    globalStack.push(a);
    globalStack.push(b);
}

///
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("1 2 exch");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);

        auto b = globalStack.pop();
        assert(b.type == PSType.number);
        assert(b.value.number == 2);

        assert(globalStack.empty);
    }
}

/// builtin stack duplicate: any1 -> any1 any1
void dupOp()
{
    // get args
    executeStack();
    auto a = globalStack.top();
    globalStack.push(*a);
}

///
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("1 dup");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);

        auto b = globalStack.pop();
        assert(b.type == PSType.number);
        assert(b.value.number == 1);

        assert(globalStack.empty);
    }
}

/// builtin stack index: ... any_n ... any_0 n -> ... any_n ... any_0 any_n
void indexOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop();
    assert(a.type == PSType.number, "arg of `index` should be number");
    auto i = globalStack.top(a.value.number);
    globalStack.push(*i);
}

///
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("1 2 3 1 index");
        eval();
        assert(globalStack.length == 4);
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 2);
    }
}

/// builtin stack roll: any_n ... any_0 n j -> any_{k-1} ... any_0 any_n ... any_k (where k = j % n)
void rollOp()
{
    // get args
    executeStack();
    auto jo = globalStack.pop();
    assert(jo.type == PSType.number, "1st arg of `roll` should be number");
    auto no = globalStack.pop();
    assert(no.type == PSType.number, "2nd arg of `roll` should be number");
    auto n = no.value.number;
    auto j = jo.value.number % n;

    auto topn = globalStack.topk(n);
    foreach (i; 0 .. j)
    {
        auto tmp = topn[i];
        auto k = (i + j) % n;
        topn[i] = topn[k];
        topn[k] = tmp;
    }
}

///
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();
    {
        cl_getc_set_src("1 2 3 4 5 6 7 4 3 roll");
        eval(); // 1 2 3 5 6 7 4
        assert(globalStack.length == 7);
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 4);
        a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 7);
        a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 6);
        a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 5);
        a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 3);
        a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 2);
        a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);
    }
}

/*****************
 numeric operators
 *****************/

/// binary operator template
void binaryOp(string op)()
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
    mixin("ret.value.number = cast(int) b.value.number " ~ op ~ " a.value.number;");
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

/// test logical ops
unittest
{
    import cl_getc : cl_getc_set_src;

    scope (exit) clearTopLevel();

    {
        cl_getc_set_src("3 3 eq");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 2 eq");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 0);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 3 neq");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 0);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 2 neq");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 3 gt");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 0);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 2 gt");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 3 ge");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("2 3 ge");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 0);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("2 3 lt");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 3 lt");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 0);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 3 le");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 1);
        assert(globalStack.empty);
    }
    {
        cl_getc_set_src("3 2 le");
        eval();
        auto a = globalStack.pop();
        assert(a.type == PSType.number);
        assert(a.value.number == 0);
        assert(globalStack.empty);
    }
}
