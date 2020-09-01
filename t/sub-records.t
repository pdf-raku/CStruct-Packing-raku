use v6;
use Test;
use CStruct::Packing :Endian;
use NativeCall;

constant $CLIB = Rakudo::Internals.IS-WIN ?? 'msvcrt' !! Str;
sub memcpy(Pointer, Pointer, size_t) is native($CLIB) {*}
sub ptr($_) { nativecast(Pointer, $_) }

class SubStruct1 is repr('CStruct') does CStruct::Packing[NetworkEndian] {
        has uint16 $.a;
        has uint8  $.b;
}

class SubStruct2 is repr('CStruct') does CStruct::Packing[VaxEndian] {
        has uint32 $.c;
}

class SubStruct3 is repr('CStruct') {
        has uint16 $.d;
}

class NetStruct is repr('CStruct') does CStruct::Packing[NetworkEndian] {
    HAS SubStruct1 $.s1;
    has uint16 $.v;
    HAS SubStruct2 $.s2;
    HAS SubStruct3 $.s3;
    submethod BUILD(:$!v = 0, SubStruct1 :$s1, SubStruct2 :$s2,  SubStruct3 :$s3) {
        memcpy(ptr(self.s1), ptr($_), nativesizeof($_)) with $s1;
        memcpy(ptr(self.s2), ptr($_), nativesizeof($_)) with $s2;
        memcpy(ptr(self.s3), ptr($_), nativesizeof($_)) with $s3;
    }
}

my $s1 = SubStruct1.new(:a(42), :b(99));
my $s2 = SubStruct2.new(:c(42));
my $s3 = SubStruct3.new(:d(123));

my $n = NetStruct.new: :v(42), :$s1, :$s2, :$s3;

my $n-buf = $n.pack;
is-deeply $n-buf.list, (
    0,42, 99,
    0,42,
    42,0,0,0,
    0, 123), 'network struct packing';

my $n2 = NetStruct.unpack($n-buf);
is-deeply $n2, $n, 'network struct unpacking';

is-deeply NetStruct.new.pack.list, (0 xx 11), 'network packing empty';

class VaxStruct is repr('CStruct') does CStruct::Packing[VaxEndian] {
    HAS SubStruct1 $.s1 is built;
    has uint16 $.v;
    HAS SubStruct2 $.s2 is built;
    HAS SubStruct3 $.s3;
    submethod BUILD(:$!v = 0, SubStruct1 :$s1, SubStruct2 :$s2,  SubStruct3 :$s3) {
        memcpy(ptr(self.s1), ptr($_), nativesizeof($_)) with $s1;
        memcpy(ptr(self.s2), ptr($_), nativesizeof($_)) with $s2;
        memcpy(ptr(self.s3), ptr($_), nativesizeof($_)) with $s3;
    }
}

my $v = VaxStruct.new: :$s1, :v(42), :$s2, :$s3;

my $v-buf = $v.pack;
is-deeply $v-buf.list, (
    0,42, 99,
    42,0,
    42,0,0,0,
    123, 0), 'vax struct packing';

my $v2 = VaxStruct.unpack($v-buf);
is-deeply $v2, $v, 'vax struct unpacking';

is-deeply VaxStruct.new.pack.list, (0 xx 11), 'vax packing empty';

done-testing;
