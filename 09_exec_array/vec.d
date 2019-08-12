module vec;

import core.stdc.stdlib : realloc, free, malloc;

/// Dynamic array
struct Vec(T)
{
    /// the number of items
    size_t length = 0;
    /// the size of allocated memory
    size_t capacity = 0;
    /// pointer to storage
    T* ptr = null;

    /// not copyable
    @disable this(this);
    /// ditto
    @disable new(size_t);

    /// automatically free resources when this exits scope
    ~this()
    {
        free();
    }

    /// manual free
    void free()
    {
        import core.stdc.stdlib : free;
        free(this.ptr);
        this.ptr = null;
    }

    /// get element by index
    ref inout(T) at(size_t n) inout
    {
        assert(this.length > n);
        return this.ptr[n];
    }

    /// reserve memory
    void reserve(size_t n, bool force = false)
    {
        if (!force && this.capacity >= n + this.length) return;

        this.capacity = n + this.length;
        auto old = this.ptr;
        this.ptr = cast(T*) realloc(old, T.sizeof * this.capacity);
        assert(this.ptr, "realloc failed");
    }

    /// shrink capacity to length
    void shrink()
    {
        if (this.length == 0) this.free();
        if (this.capacity == this.length) return;
        this.reserve(0, true);
    }

    /// resize array but not free memory
    void resize(size_t n)
    {
        this.reserve(n);
        size_t prevLength = this.length;
        this.length = n;
        for (size_t i = prevLength; i < this.length; ++i)
        {
            this.at(i) = T.init;
        }
    }

    /// clear items but not free memory
    void clear()
    {
        this.length = 0;
    }

    /// check length == 0
    bool empty()
    {
        return this.length == 0;
    }

    /// push new item to back
    T* pushBack(T x)
    {
        if (length == this.capacity) {
            this.reserve(2 * length + 1);
        }
        ++this.length;
        this.at(this.length - 1) = x;
        return this.ptr + this.length - 1;
    }
}

nothrow @nogc
unittest
{
    Vec!int v;
    assert(v.empty);
    v.pushBack(1);
    assert(v.at(0) == 1);

    v.resize(2);
    assert(v.length == 2);
    assert(v.at(0) == 1);
    assert(v.at(1) == int.init);

    v.resize(1);
    assert(v.at(0) == 1);
    assert(v.length == 1);

    assert(v.capacity != v.length);
    v.shrink();
    assert(v.capacity == v.length);

    v.resize(0);
    assert(v.length == 0);

    assert(v.capacity != v.length);
    v.shrink();
    assert(v.capacity == v.length);
}
