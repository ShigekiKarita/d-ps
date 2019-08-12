module dict;

/// Dictionary to store key-value pairs
struct Dict(Key, Value)
{
    struct Item
    {
        Key key;
        Value value;
    }

    Item[1024] payload;
    size_t length = 0;

    Item[] items()
    {
        return this.payload[0 .. this.length];
    }

    void put(Key k, Value v)
    {
        auto vp = this.get(k);
        if (vp !is null)
        {
            *vp = v;
        }
        else
        {
            assert(this.length + 1 < this.payload.length, "dictionary is full");
            ++length;
            this.items[$-1] = Item(k, v);
        }
    }

    Value* get(Key k)
    {
        foreach (ref i; this.items)
        {
            if (i.key == k)
            {
                return &i.value;
            }
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
}
