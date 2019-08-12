import core.stdc.stdio;
import cl_getc : cl_getc_set_src;
import eval : eval, globalStack, PSType, initTopLevel, printGlobalStack;


void main()
{
    initTopLevel();

    char[1024] buf;
    buf[$ - 1] = 1;
    printf(">>> ");
    while (fgets(buf.ptr, buf.length, stdin))
    {
        assert(buf[$-1] != 0, "too long input");
        cl_getc_set_src(buf);
        eval();
        if (globalStack.length > 0)
        {
            auto top = globalStack.pop();
            top.print();
        }
        printf(">>> ");
    }
}
