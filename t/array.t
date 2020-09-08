use v6;
use Test;
plan 2;
use CStruct::Packing :Endian;
use NativeCall;
class N is repr('CStruct') does CStruct::Packing[BigEndian] is repr('CStruct') {
    has uint8  $.a;
    has uint16 $.b;
}

my CArray[N] $Ns .= new: (1..3).map: {
    N.new: :a(2 * $_), :b(10 * $_);
}

my Blob $packed = N.pack-array($Ns);
is-deeply $packed, Buf[uint8].new(
    2, 0,10,
    4, 0,20,
    6, 0,30,
);

my $Ns-again = N.unpack-array($packed);
is-deeply $Ns-again, $Ns;

done-testing;
