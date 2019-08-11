import core.stdc.stdio : EOF;
import cl_getc : cl_getc, cl_getc_set_src;
import parser : parseOne;

int main()
{
    int answer1 = 0;
    int answer2 = 0;

    cl_getc_set_src("123 456");

    // write something here.
    int c;
    while ((c = cl_getc()) != ' ')
    {
        answer1 = answer1 * 10 + (c - '0');
    }
    while ((c = cl_getc()) == ' ') {}
    answer2 = c - '0';
    while ((c = cl_getc()) != EOF)
    {
        answer2 = answer2 * 10 + (c - '0');
    }

    // // sample for cl_getc() usage.
    // int c;

    // while((c = cl_getc()) != EOF) {
    //     printf("%c\n",c );
    // }

    // verity result.
    assert(answer1 == 123);
    assert(answer2 == 456);

    return 0;


}
