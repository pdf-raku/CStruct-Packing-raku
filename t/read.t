use v6;
use Test;
use CStruct::Packing :Endian;
use NativeCall;

constant $CLIB = Rakudo::Internals.IS-WIN ?? 'msvcrt' !! Str;
sub memcpy(Pointer, Pointer, size_t) is native($CLIB) {*}

class NetStruct is rw is repr('CStruct') does CStruct::Packing[NetworkEndian] {
    has uint16 $.v;
}

class VaxStruct is rw is repr('CStruct') does CStruct::Packing[VaxEndian] {
    has uint16 $.v;
}

class N is repr('CStruct') does CStruct::Packing[NetworkEndian] {
    has uint8  $.a;
    has uint16 $.b;
    has uint8  $.c;
    has num32  $.float;
    HAS NetStruct $.net;
    HAS VaxStruct $.vax;
}

my $struct = N.unpack(Buf[uint8].new(10, 0,20, 30, 66,40,0,0, 0,42, 99,0));
given $struct {
    is .a, 10;
    is .b, 20;
    is .c, 30;
    is .float, 42e0;
    is .net.v, 42;
    is .vax.v, 99;
}

my $out-fh = "t/net.bin".IO.open(:bin, :w);
$struct.write: $out-fh;
$out-fh.close;
my $n-buf = "t/net.bin".IO.open(:bin, :r).read;
is-deeply $n-buf, Buf[uint8].new(10, 0,20, 30, 66,40,0,0, 0,42, 99,0), 'network write';

my $n-struct = N.read: "t/net.bin".IO.open(:bin, :r);
is-deeply $n-struct, $struct, 'network write/read round-trip';

class V is repr('CStruct') does CStruct::Packing[VaxEndian] {
    has uint8  $.a;
    has uint16 $.b;
    has uint8  $.c;
    has num32  $.float;
    HAS NetStruct $.net is built;
    HAS VaxStruct $.vax is built;
}

$struct = V.unpack(Buf[uint8].new(10, 20,0, 30,0,0,40,66, 0,42, 99,0));
given $struct {
    is .a, 10;
    is .b, 20;
    is .c, 30;
    is .float, 42e0;
    is .net.v, 42;
    is .vax.v, 99;
}
$out-fh = "t/vax.bin".IO.open(:bin, :w);
$struct.write: $out-fh;
$out-fh.close;
my $v-buf = "t/vax.bin".IO.open(:bin, :r).read;
is-deeply $v-buf, Buf[uint8].new(10, 20,0, 30,0,0,40,66, 0,42, 99,0), 'vax write';

my $v-struct = V.read: "t/vax.bin".IO.open(:bin, :r);
is-deeply $v-struct, $struct, 'vax write/read round-trip';

done-testing;


