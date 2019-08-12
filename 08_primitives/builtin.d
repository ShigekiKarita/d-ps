module builtin;

@nogc nothrow:

import eval; // : executeStack, globalNames, globalStack;


void addOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop();
    assert(a.type == PSType.number, "1st arg of add should be number");

    executeStack();
    auto b = globalStack.pop();
    assert(b.type == PSType.number, "2nd arg of add should be number");

    // set return value
    PSObject ret;
    ret.type = PSType.number;
    ret.value.number = a.value.number + b.value.number;
    globalStack.push(ret);
}


void defOp()
{
    // get args
    executeStack();
    auto a = globalStack.pop();
    assert(a.type == PSType.number, "1st arg of add should be number");

    executeStack();
    auto b = globalStack.pop();
    assert(b.type == PSType.literalName, "2nd arg of add should be literal name");

    // put name into global dict
    globalNames.put(b.value.name, a);

}
