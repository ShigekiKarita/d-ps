module stack;

struct Stack(T, size_t N = 1024)
{
    T[N] payload;
    size_t length = 0;

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

    T* top()
    {
        if (length == 0) return null;
        return this.payload.ptr + length - 1;
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
