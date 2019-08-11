module cl_getc;

static string input = "123 456";
static int pos = 0;

int cl_getc()
{
    import core.stdc.stdio : EOF;
    import core.stdc.string : strlen;
    if(strlen(input.ptr) == pos)
        return EOF;
    return input[pos++];
}
