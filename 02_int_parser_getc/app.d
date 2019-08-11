import core.stdc.stdio;
import cl_getc : cl_getc;


int parse_one()
{

}

int main()
{
    int answer1 = 0;
    int answer2 = 0;

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

    /+
    // sample for cl_getc() usage.
    int c;

    while((c = cl_getc()) != EOF) {
        printf("%c\n",c );
    }
    +/

    // verity result.
    assert(answer1 == 123);
    assert(answer2 == 456);
    printf("test passed: %d\n", answer1);
    return 0;
}
