module dict;

/// stupid hash function
@nogc nothrow
hash_t simpleHash(const (char)[] data)
{
    hash_t ret = 0;
    foreach (d; data)
    {
        ret += d;
    }
    return ret;
}

/// ditto
@nogc nothrow
hash_t simpleHash(T)(auto ref T x)
{
    static assert(T.sizeof % char.sizeof == 0);
    auto p = cast(char*) &x;
    return simpleHash(p[0 .. T.sizeof]);
}

///
@nogc nothrow
unittest
{
    string s1 = "abc";
    string s2 = "abcd";
    assert(s1 !is s2);
    assert(simpleHash(s1) == simpleHash(s2[0 .. 3]));
    assert(simpleHash("abc") != simpleHash("ab"));
    assert(simpleHash(123) != simpleHash(12));
}

/// internal list to store conflicted keys
struct LinkedList(T)
{
    T data;
    LinkedList!T* next;
}

/// Dictionary to store key-value pairs
struct Dict(Key, Value, size_t HASH_SIZE = 1024, alias hashfun = simpleHash)
{
    /// Key-value pair
    struct Item
    {
        Key key;
        Value value;
    }

    alias List = LinkedList!Item;

    /// internal list to store conflicted keys
    List*[HASH_SIZE] payload;

    /// the number of items
    size_t length = 0;

    /// free payload
    ~this()
    {
        foreach (ref p; payload)
        {
            import core.stdc.stdlib : free;

            if (p is null) continue;

            auto ptr = p.next;
            p = null;
            while (ptr !is null)
            {
                auto next = ptr.next;
                free(ptr);
                ptr = next;
            }
        }
    }

    /// get index of key on payload
    size_t indexOf(Key k)
    {
        return hashfun(k) % this.payload.length;
    }

    /// put new item
    void put(Key k, Value v)
    {
        import core.stdc.stdlib : malloc;

        auto vp = this.get(k);
        if (vp !is null)
        {
            *vp = v;
            return;
        }

        // put new item
        ++length;
        auto newItem = cast(List*) malloc(List.sizeof);
        *newItem = List(Item(k, v), null);
        auto i = this.indexOf(k);
        auto p = this.payload[i];

        // put in the front of list
        if (p is null)
        {
            this.payload[i] = newItem;
            return;
        }

        // put in the back of list
        while (p.next != null) p = p.next;
        p.next = newItem;
    }

    /// get value of key
    Value* get(Key k)
    {
        for (auto p = this.payload[this.indexOf(k)]; p != null; p = p.next)
        {
            if (p.data.key == k)
                return &p.data.value;
        }
        return null;
    }
}

///
@nogc nothrow
unittest
{
    Dict!(int, string) d;
    d.put(123, "hello");
    assert(*d.get(123) == "hello");
    assert(d.get(321) is null);
    assert(d.length == 1);

    d.put(123, "hi");
    assert(*d.get(123) == "hi");

    d.put(1, "");
    assert(*d.get(1) == "");
}
