use v6;
use Test;
plan 12;
use NativeCall;
use CStruct::Packing :&mem-unpack, :Endian;

my buf8 $vax-buf .= new(10,0, 20,0, 30,0);
my $out = mem-unpack(CArray[uint16], $vax-buf, :endian(VaxEndian));
isa-ok($out, CArray[uint16]);
is $out.elems, 3;
is $out[0], 10;
is $out[1], 20;
is $out[2], 30;

my buf8 $nw-buf .= new(1,11, 0,21, 0,31);
mem-unpack($out, $nw-buf, :endian(NetworkEndian));
isa-ok($out, CArray[uint16]);
is $out.elems, 3;
is $out[0], 256 + 11;
is $out[1], 21;
is $out[2], 31;

my $buf = mem-pack($out, :endian(NetworkEndian));
is-deeply $buf, buf8.new(1,11, 0,21, 0,31);

$buf = mem-pack($out, :endian(VaxEndian));
is-deeply $buf, buf8.new(11,1, 21,0, 31,0);

