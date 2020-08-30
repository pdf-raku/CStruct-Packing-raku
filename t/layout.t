use v6;
use Test;
use CStruct::Packing :Endian;
plan 1;

use NativeCall;

class SubStruct1 is repr('CStruct') does CStruct::Packing[NetworkEndian] {
    has uint16 $.a;
    has uint8  $.b;
}

class SubStruct2 is repr('CStruct') does CStruct::Packing[VaxEndian] {
    has uint32 $.c;
}

class NetStruct is repr('CStruct') does CStruct::Packing[NetworkEndian] {
    HAS SubStruct1 $.s1;
    has uint16 $.v;
    HAS SubStruct2 $.s2;
}

my @layout = NetStruct.layout.list;
if $*KERNEL.endian == LittleEndian {
    is-deeply @layout, [0, -2,   0, -1,   1, -2,   2,  4,   0, 0];
}
else {
    is-deeply @layout, [0,  2,   0,  1,   1,  2,   2, -4,   0, 0];
}

done-testing;
