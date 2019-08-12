import core.stdc.stdio;
import cl_getc : cl_getc_set_src;
import eval : eval, globalStack, PSType;

void main()
{
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
            assert(globalStack.length == 0, "stack is not empty after eval()");
            assert(top.type == PSType.number, "unsupported type to print");
            printf("%d\n", top.value.number);
        }
        printf(">>> ");
    }
}
