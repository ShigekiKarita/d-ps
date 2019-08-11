import core.stdc.stdio;

string input = "123 456  1203";

int main()
{
    int answer1 = 0;
    int answer2 = 0;
    int answer3 = 0;

    // write something here.
    size_t i = 0;
    for (; input[i] != ' '; ++i)
    {
        answer1 = 10 * answer1 + (input[i] - '0');
    }
    while (input[i] == ' ') ++i;
    for (; input[i] != ' '; ++i)
    {
        answer2 = 10 * answer2 + (input[i] - '0');
    }
    while (input[i] == ' ') ++i;
    for (; i < input.length; ++i)
    {
        answer3 = 10 * answer3 + (input[i] - '0');
    }

    // verity result.
    assert(answer1 == 123);
    assert(answer2 == 456);
    assert(answer3 == 1203);
    printf("test passed: %d\n", answer1);
    return 0;
}
