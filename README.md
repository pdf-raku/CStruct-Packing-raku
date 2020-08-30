CStruct-Packing-raku
===============

[![Build Status](https://travis-ci.org/pdf-raku/CStruct-Packing-raku.svg?branch=master)](https://travis-ci.org/pdf-raku/CStruct-Packing-raku)

## Description

CStruct::Packing is a simple solution for structured reading
and writing of CStructs as binary numerical data.

The module is an alternative to Native::Packing. It requires all structures
to be native CStructs, but can be signficantly faster.

## Example

```
use v6;
use CStruct::Packing :Endian;

# open a GIF read the header
my class LogicalDescriptor
    is repr('CStruct')
    does CStruct::Packing[VaxEndian] {

    has uint16 $.width;
    has uint16 $.height;
    has uint8  $.flags;
    has uint8  $.bgColorIndex;
    has uint8  $.aspect;
}

my $fh = "t/lightbulb.gif".IO.open( :r, :bin);
my $offset = 6;  # skip GIF header

my LogicalDescriptor $screen .= read: $fh, :$offset;
say "GIF has size {$screen.width} X {$screen.height}";
```

It currently handles records containing native integers (`int8`, `uint8`, `int16`, etc),
numerics (`num32`, `num64`) and sub-records of type `CStruct::Packing`. These
must be declared as inline structs, using the `HAS` keyword.

- Data may read be and written to binary files, via the `read` and `write` methods

-  Or read and written to buffers via the `unpack` and `pack` methods.

### Endianess

The two fixed modes are:

- VaxEndian (or LittleEndian) - least significant byte written first

- Network (or BigEndian) - most significant byte written first

There is also a platform-dependant `Host` mode. This will read and write
binary data in the same endianess as the host computer.

Endian Examples:

```
use CStruct::Packing :Endian;

class C is repr('CStruct') { has int16 $.a }
class C-vax  is repr('CStruct') is C does CStruct::Packing[VaxEndian] {}
class C-net  is repr('CStruct') is C does CStruct::Packing[NetworkEndian] {}
class C-host is repr('CStruct') is C does CStruct::Packing[HostEndian] {}

say C-vax.new(:a(42)).pack;    # Buf[uint8]:0x<2a 00>
say C-net.new(:a(42)).pack;    # Buf[uint8]:0x<00 2a>
say C-host.new(:a(42)).pack;   # Depends on your host

```

## Methods

### pack

    method pack(Any:D: Blob $buf?, :$layout --> Blob)

Returns a packed representation of the CStruct as a Blob.

### unpack

    method unpack(Blob:D $buf, :$layout --> Any:D)

Unpacks the buffer. If this method is called from an object, the object's
contents are replaced. Otherwise a new object is returned.

### read

    method read(IO::Handle \fh, UInt :$offset, :$layout -> Any:D)

Utility method to read and unpack a structure from a file handle.

### write

    method read(IO::Handle \fh, UInt :$offset, :$layout)

Uitility method to pack and write a structure to a file handle.


### layout

    method layout(--> CArray)

Precomputes the memory layout for a structure.

    my $layout = Rec.layout; # precompute layout
    my @recs = 100 xx Rec.read($fh, :$layout);

### packed-size

    method packed-size(--> size_t)

Returns the size of the packed structure

### unpacked-size

    method unpacked-size(--> size_t)

Returns the size of the packed structure. S.unpacked-size should be equal
to nativesizeof(S).