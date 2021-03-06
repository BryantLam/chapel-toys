// chpl version 1.23.0 pre-release (a25ae3153)
module StringSerialize {

private use SysCTypes;

param identField = 0;
param sizeField = 1;
param dataField = 9;

proc serialize(s: string): c_ptr(uint(8)) {
    var buffer = c_malloc(uint(8), s.numBytes + dataField);

    //
    // Warning: Does not handle endian mismatch.
    //
    // Format
    //  byte 0 = literal 's' for string
    //  byte 1-8 = 8-byte size of data
    //  byte 9+ = data
    //
    if s.numBytes.type != int(64) then compilerError("size type is not 8 bytes"); // How to param check size of type?

    buffer[identField] = b"s".toByte();

    assert(c_sizeof(c_longlong) == c_sizeof(int(64))); // How to param check size of type?
    var numBytes = s.numBytes :c_longlong; // c_int64 does not exist.
    assert(numBytes == s.numBytes);
    writeln(("numBytes", numBytes));
    // Cannot use c_ptrTo(s.numBytes). Convert from `int` to `c_<integral>` and use `numBytes` instead.
    c_memcpy(c_ptrTo(buffer[sizeField]), c_ptrTo(numBytes), 8);

    c_memcpy(c_ptrTo(buffer[dataField]), s.c_str() :c_void_ptr, s.numBytes);

    return buffer;
}

proc deserialize(type T, buffer: c_ptr(uint(8))): T where T == string {
    defer {
        if buffer {
            c_free(buffer);
        }
    }

    assert(buffer[identField] == b"s".toByte());

    // var numBytes: "".size.type = 0; // How to get string.size.type?
    var numBytes: c_longlong = 0;
    c_memcpy(c_ptrTo(numBytes), c_ptrTo(buffer[sizeField]), 8);
    assert(numBytes != 0);

    try! write("[%02xu".format(buffer[0]));
    for i in 1..<(numBytes + dataField) {
        try! write(" %02xu".format(buffer[i]));
    }
    writeln("]");
    writeln(("numBytes", numBytes));

    try {
        var s = createStringWithNewBuffer(c_ptrTo(buffer[dataField]), numBytes);
        return s;
    } catch {
        halt("createStringWithNewBuffer");
    }
}

proc main() {
    var input = "Hello\x00World";
    writeln(("input", input));

    var tx = serialize(input);
    writeln(tx);

    var rx = deserialize(input.type, tx);
    writeln(("output", rx));
}

} // module StringSerialize
