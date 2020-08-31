use Test;
use CStruct::Packing;
use NativeCall;
plan 2;

class BaseStruct {
    has uint16 $.a;
    has uint8  $.b;
    has uint8  $.c;
}

class Struct
    is BaseStruct
    is repr('CStruct')
    does CStruct::Packing[BigEndian] {
    has uint16 $.c;
}

is Struct.unpacked-size, nativesizeof(Struct);
my $s = Struct.new: :a(42), :b(99), :c(69);
my $n-buf = $s.pack;
is-deeply $n-buf.list, (
    0,42,
    99,
    0,69), 'network packing with inheritance';

done-testing;
