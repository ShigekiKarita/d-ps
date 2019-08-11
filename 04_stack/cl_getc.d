module cl_getc;

@nogc nothrow:

static const(char)* input = "123 456";
static int pos = 0;

void cl_getc_set_src(string str)
{
    import core.stdc.string : memcpy;
    input = str.ptr;
    pos = 0;
}

int cl_getc()
{
    import core.stdc.stdio : EOF;
    import core.stdc.string : strlen;
    if(strlen(input) == pos)
        return EOF;
    return input[pos++];
}
