module dict;

@nogc nothrow:

/// stupid hash function
hash_t simple_hash(const (char)[] data)
{
    hash_t ret = 0;
    foreach (d; data)
    {
        ret += d;
    }
    return ret;
}

hash_t simple_hash(T)(auto ref T x)
{
    static assert(T.sizeof % char.sizeof == 0);
    auto p = cast(char*) &x;
    return simple_hash(p[0 .. T.sizeof]);
}

unittest
{
    assert(simple_hash("abc") != simple_hash("ab"));
    assert(simple_hash(123) != simple_hash(12));
}

struct LinkedList(T)
{
    T value;
    LinkedList!T* next;
}

/// Dictionary to store key-value pairs
struct Dict(Key, Value, size_t HASH_SIZE = 1024)
{
    @nogc nothrow:

    struct Item
    {
        Key key;
        Value value;
    }

    alias List = LinkedList!Item;
    List*[HASH_SIZE] payload;
    size_t length = 0;

    void put(Key k, Value v)
    {
        auto vp = this.get(k);
        if (vp !is null)
        {
            *vp = v;
        }
        else
        {
            import core.stdc.stdlib : malloc;

            ++length;

            auto newItem = cast(List*) malloc(List.sizeof);
            *newItem = List(Item(k, v), null);

            auto i = simple_hash(k) % this.payload.length;
            auto p = this.payload[i];
            if (p is null)
            {
                this.payload[i] = newItem;
                return;
            }
            else
            {
                while (p.next != null) p = p.next;
                p.next = newItem;
            }
        }
    }

    Value* get(Key k)
    {
        auto i = simple_hash(k) % this.payload.length;
        for (auto p = this.payload[i]; p != null; p = p.next)
        {
            if (p.value.key == k)
                return &p.value.value;
        }
        return null;
    }
}

///
// @nogc nothrow
unittest
{
    Dict!(int, string) d;
    d.put(123, "hello");
    assert(*d.get(123) == "hello");
    assert(d.get(321) is null);
    assert(d.length == 1);

    d.put(123, "hi");
    assert(*d.get(123) == "hi");
}
