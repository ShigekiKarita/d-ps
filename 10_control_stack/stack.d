module stack;

struct Stack(T, size_t N = 1024)
{
    T[N] payload;
    size_t length = 0;

    bool empty() pure
    {
        return length == 0;
    }

    void push(T item)
    {
        assert(length < payload.length, "stack overflow");
        payload[length] = item;
        ++length;
    }

    T pop()
    {
        assert(length > 0, "empty stack");
        --length;
        return payload[length];
    }

    T* top(size_t i = 0) pure
    {
        if (length <= i) return null;
        return this.payload.ptr + length - i - 1;
    }

    T[] topk(size_t k)
    {
        debug if (length <= k)
        {
            import core.stdc.stdio : fprintf, stderr;
            fprintf(stderr, "ERROR: length (%d) <= k (%d)", length, k);
            assert(false, "ERROR: too many request");
        }
        return this.payload.ptr[length - k .. length];
    }
}

unittest
{
    Stack!int s;
    s.push(2);
    s.push(1);
    assert(s.length == 2);
    assert(*s.top == 1);
    assert(s.pop() == 1);
    assert(s.length == 1);
    assert(*s.top == 2);
    assert(s.pop() == 2);
    assert(s.length == 0);
}
