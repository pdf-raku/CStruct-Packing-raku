use Test;
plan 24;
use CStruct::Packing :Endian;
use NativeCall;

class N16 does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has uint16 $.b;
    has uint8  $.c;
}

my N16 $n16 .= unpack: N16.new(:a(42), :b(0x1234), :c(99)).pack;
is $n16.a, 42;
is $n16.b, 0x1234;
is $n16.c, 99;

class N32 does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has uint32 $.b;
    has uint8  $.c;
}

my N32 $n32 .= unpack: N32.new(:a(42), :b(0x12345678), :c(99)).pack;
is $n32.a, 42;
is $n32.b, 0x12345678;
is $n32.c, 99;

class N64 does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has uint64 $.b;
    has uint8  $.c;
}

my N64 $n64 .= unpack: N64.new(:a(42), :b(0x1234567812345678), :c(99)).pack;
is $n64.a, 42;
is $n64.b, 0x1234567812345678;
is $n64.c, 99;


class N32-num does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has num32 $.b;
    has uint8  $.c;
}

my N32-num $n32-num .= unpack: N32-num.new(:a(42), :b(12345e-1), :c(99)).pack;
is $n32-num.a, 42;
is $n32-num.b, 12345e-1;
is $n32-num.c, 99;

class N64-num does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has num64 $.b;
    has uint8  $.c;
}

my N64-num $n64-num .= unpack: N64-num.new(:a(42), :b(1234512345e-1), :c(99)).pack;
is $n64-num.a, 42;
is $n64-num.b, 1234512345e-1;
is $n64-num.c, 99;

class N-size_t does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has size_t $.b;
    has uint8  $.c;
}

my N-size_t $n-size_t .= unpack: N-size_t.new(:a(42), :b(1234512345), :c(99)).pack;
is $n-size_t.a, 42;
is $n-size_t.b, 1234512345;
is $n-size_t.c, 99;

class N-long does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has long $.b;
    has uint8  $.c;
}

my N-long $n-long .= unpack: N-long.new(:a(42), :b(1234512345), :c(99)).pack;
is $n-long.a, 42;
is $n-long.b, 1234512345;
is $n-long.c, 99;

class N-longlong does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has longlong $.b;
    has uint8  $.c;
}

my N-longlong $n-longlong .= unpack: N-longlong.new(:a(42), :b(1234512345), :c(99)).pack;
is $n-longlong.a, 42;
is $n-longlong.b, 1234512345;
is $n-longlong.c, 99;
