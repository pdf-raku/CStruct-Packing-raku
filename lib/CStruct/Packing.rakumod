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

sub packing_pack(Pointer, Blob, CArray --> size_t) is native(PACKING-LIB) { * }
sub packing_unpack(Pointer, Blob, CArray --> size_t) is native(PACKING-LIB) { * }
sub packing_packed_size(CArray --> size_t) is native(PACKING-LIB) { * }
sub packing_struct_size(CArray --> size_t) is native(PACKING-LIB) { * }


my role Packing {

    method host-endian { HostEndian }

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
    method !attributes {
        storage-atts(self.WHAT);
    }

}

role CStruct::Packing[Endian $endian = HostEndian]
    does Packing {

    method pack(Any:D: Blob $buf? is copy, :$layout = self.layout --> Blob) {
        my $bytes := packing_packed_size($layout);
        $buf //= buf8.allocate($bytes);
        die "buffer size ({$buf.bytes}) < {$bytes} bytes" unless $buf.bytes >= $bytes;
        packing_pack(nativecast(Pointer, self), $buf, $layout);
        $buf;
    }

    method unpack(Blob:D $buf is copy, :$layout = self.layout, UInt :$offset) {
        my $bytes := packing_packed_size($layout);
        $buf .= subbuf($offset) if $offset;
        die "buffer size ({$buf.bytes}) < {$bytes} bytes" unless $buf.bytes >= $bytes;
        my $obj := do with self { $_ } else { .new }
        packing_unpack(nativecast(Pointer, $obj), $buf, $layout);
        $obj;
    }

    method read(IO::Handle \fh, UInt :$offset, :$layout = self.layout) {
        fh.read($_) with $offset;
        my $buf := fh.read(packing_packed_size($layout));
        self.unpack($buf, :$layout);
    }

    method write(Any:D: IO::Handle \fh, :$layout = self.layout) {
        fh.write: self.pack(:$layout);
    }

    method layout(Bool :$terminate = True --> CArray) {
        my @vec;
        my $offset = 0;
        my $max-size = 0;

        for self!attributes -> $att {
            
            given $att.type {
                when CStruct::Packing {
                    die "can only handle inline structs (please use HAS on sub-structs)"
                        unless $att.inlined;
                    my @sub-vect = .layout(:!terminate).list;
                    if @sub-vect {
                        my @sizes = @sub-vect.map(*.abs);
                        my $size = @sizes.max;
                        my $pad = $offset %% $size ?? 0 !! $size - $offset % $size;
                        @sub-vect[0] = $pad;
                        @vec.append: @sub-vect;
                        $offset += @sizes.sum
                    }
                }
                default {
                    my $size := nativesizeof($_);
                    $max-size = $size if $size > $max-size;
                    my $pad = $offset %% $size ?? 0 !! $size - $offset % $size;
                    $offset += $pad + $size;
                    @vec.push: $pad;
                    @vec.push: ($endian == HostEndian ?? 1 !! -1) * $size;
                }
            }
        }
        if $terminate {
            my $pad = $offset % $max-size;
            @vec.push: $pad;
            @vec.push: 0;
        }
        CArray[int8].new: @vec;
    }

    method packed-size(:$layout = self.layout) { packing_packed_size($layout) }
    method struct-size(:$layout = self.layout) { packing_struct_size($layout) }
}
