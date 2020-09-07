use v6;
use NativeCall;
use NativeCall::Types;

=begin pod

=head1 NAME

CStruct::Packing

=head1 DESCRIPTION

This module provides a role for binary serialization of simple structs. At this stage, only scalar native integer and numeric attributes are supported.

This role is applicable to classes that contain only simple native numeric
attributes, representing the structure of the data.

=head1 EXAMPLE

    use v6;
    use CStruct::Packing :Endian;

    # open a GIF read the 'screen' header
    my class GifHeader
        is repr('CStruct')
        does CStruct::Packing[BigEndian] {

        has uint16 $.width;
        has uint16 $.height;
        has uint8 $.flags;
        has uint8 $.bgColorIndex;
        has uint8 $.aspect;
    }

    my $fh = "t/lightbulb.gif".IO.open( :r :bin);
    $fh.read(6);  # skip GIF header

    my GifHeader $screen .= read: $fh;

    say "GIF has size {$screen.width} X {$screen.height}";

=head1 METHODS

=head2 unpack(buf8)

Class level method. Unpack bytes from a buffer. Create a struct object.

=head2 pack(buf8?)

Object level method. Serialize the object to a buffer.

=head2 read(fh)

Class level method. Read data from a binary file. Create an object.

=head2 write(fh)

Object level method. Write the object to a file

=head2 bytes

Determine the overall size of the struct. Sum of all its attributes.

=head2 host-endian

Return the endian of the host BigEndian or LittleEndian.

=end pod

use NativeCall;

constant PACKING-LIB = %?RESOURCES<libraries/packing>;
constant NetworkEndian is export(:NetworkEndian,:Endian) = BigEndian;
constant VaxEndian is export(:VaxEndian,:Endian) = LittleEndian;
constant HostEndian is export(:HostEndian,:Endian) = $*KERNEL.endian;

role CStruct::Packing {...}

# compute eight byte alignment, which can be platform dependant;

multi sub alignment(num64)  {
    class Num64 is repr('CStruct') { has byte $!b; has num64 $!v};
    nativesizeof(Num64) - nativesizeof(num64);
}
multi sub alignment(int64)  {
    class Int64 is repr('CStruct') { has byte $!b; has int64 $!v};
    nativesizeof(Int64) - nativesizeof(int64);
}
multi sub alignment(uint64) { alignment(int64) }
multi sub alignment($_) {
    .REPR eq 'CStruct'
        ?? .^attributes.map({ alignment(.type) }).max
        !! nativesizeof($_);
}

sub packing_pack(Pointer, Blob, size_t, CArray --> size_t) is native(PACKING-LIB) { * }
sub packing_unpack(Pointer, Blob, size_t, CArray --> size_t) is native(PACKING-LIB) { * }
sub packing_packed_size(CArray --> size_t) is native(PACKING-LIB) { * }
sub packing_struct_size(CArray --> size_t) is native(PACKING-LIB) { * }

sub storage-atts($class, :%pos, :@atts) {
    storage-atts($_, :%pos, :@atts) for $class.^parents;
    for $class.^attributes(:local) -> $att {
        my $name := $att.name;
        with %pos{$name} {
            @atts[$_] = $att;
        }
        elsif $name {
            %pos{$name} = +@atts;
            @atts.push: $att;
        }
    }
    @atts;
}

role CStruct::Packing:ver<0.0.1>[Endian \endian = HostEndian] {

    method host-endian { HostEndian }

    method pack(Any:D: Blob $buf? is copy, :$layout = self.packing-layout --> Blob) {
        my $bytes := packing_packed_size($layout);
        $buf //= buf8.allocate($bytes);
        die "buffer size ({$buf.bytes}) < {$bytes} bytes" unless $buf.bytes >= $bytes;
        packing_pack(nativecast(Pointer, self), $buf, $buf.bytes, $layout);
        $buf;
    }

    method unpack(Blob:D $buf is copy, :$layout = self.packing-layout, UInt :$offset, Bool :$pad) {
        my $bytes := packing_packed_size($layout);
        $buf .= subbuf($offset) if $offset;
        die "buffer size ({$buf.bytes}) < {$bytes} bytes"
            if $buf.bytes < $bytes && !$pad;
        my $obj := do with self { $_ } else { .new }
        packing_unpack(nativecast(Pointer, $obj), $buf, $buf.bytes, $layout);
        $obj;
    }

    method read(IO::Handle \fh, UInt :$offset, :$layout = self.packing-layout, |c) {
        fh.read($_) with $offset;
        my $buf := fh.read(packing_packed_size($layout));
        self.unpack($buf, :$layout, |c);
    }

    method write(Any:D: IO::Handle \fh, :$layout = self.packing-layout) {
        fh.write: self.pack(:$layout);
    }

    method packed-size(:$layout = self.packing-layout) { packing_packed_size($layout) }
    method unpacked-size(:$layout = self.packing-layout) { packing_struct_size($layout) }

    method packing-layout(@atts = storage-atts(self), Bool :$terminate = True, :$endian = endian // HostEndian --> CArray) {
        my @layout;
        my $offset = 0;
        my $max-size = 0;

        for @atts -> $att {

            my @sub-layout = do given $att.type {
                when .REPR eq 'CStruct' {
                    die "sub-struct {$att.name} is not in-lined (please use 'HAS' to in-line it)"
                       unless $att.inlined;

                    if .does(CStruct::Packing) {
                        .packing-layout(:!terminate).list;
                    }
                    else {
                        my @sub-atts = storage-atts($_);
                        self.packing-layout(@sub-atts, :!terminate, :$endian).list;
                    }
                }
                default {
                    my $size := nativesizeof($_);
                    $max-size = $size if $size > $max-size;
                    [Mu, ($endian == HostEndian ?? 1 !! -1) * $size];
                }
            }

            if @sub-layout {
                my $align = alignment($att.type);
                my $pad = $offset %% $align ?? 0 !! $align - $offset % $align;
                @sub-layout[0] = $pad;
                @layout.append: @sub-layout;
                $offset += .abs for @sub-layout;
            }
        }
        if $terminate {
            my $pad = $offset % $max-size;
            @layout.push: $pad;
            @layout.push: 0;
        }
        CArray[int8].new: @layout;
    }

}
