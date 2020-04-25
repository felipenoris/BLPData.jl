
function CorrelationId()
    CorrelationId(UInt32(0), CorrelationValue())
end

function CorrelationValue(val::UInt=UInt(0))
    CorrelationValue(val, (UInt(0), UInt(0), UInt(0), UInt(0)), UInt(0))
end

encode_value(val::UInt) = CorrelationValue(val)

Base.:(==)(c1::CorrelationId, c2::CorrelationId) = c1.header == c2.header && c1.value == c2.value
Base.hash(c::CorrelationId) = hash(c.header) + hash(c.value)

struct CorrelationIdHeader
    struct_size::UInt32
    correlation_type::CorrelationType
    class_id::UInt32
    reserved::UInt32

    function CorrelationIdHeader(struct_size::UInt32, correlation_type::CorrelationType, class_id::UInt32, reserved::UInt32)
        @assert struct_size <= 0xff
        @assert class_id <= 0xffff
        @assert reserved <= 0xf

        return new(struct_size, correlation_type, class_id, reserved)
    end
end

function CorrelationIdHeader(c::CorrelationId)
    CorrelationIdHeader(c.header)
end

function CorrelationIdHeader(header::UInt32)
    CorrelationIdHeader(
            # [ - 8 - ][ - 4 - ][ - 16 - ][ - 4 - ] >> 24
            # [ - zeros - ][ - 8 - ]
            header >> 24,

            # [ - 8 - ][ - 4 - ][ - 16 - ][ - 4 - ] << 8
            # [ - 4 - ][ - 16 - ][ - 4 - ][ - 8 zeros - ] >> 28
            # [ - zeros - ][ - 4 - ]
            CorrelationType(header << 8 >> 28),

            # [ - 8 - ][ - 4 - ][ - 16 - ][ - 4 - ] << 12
            # [ - 16 - ][ - 4 - ][ - 12 zeros - ] >> 16
            # [ - zeros - ][ - 16 - ]
            header << 12 >> 16,

            # [ - 8 - ][ - 4 - ][ - 16 - ][ - 4 - ] << 28
            # [ - 4 - ][ - 28 - ] >> 28
            # [ - zeros - ][ - 4 - ]
            header << 28 >> 28
        )
end

function encode_header(header::CorrelationIdHeader) :: UInt32
    (((((header.struct_size << 4) + UInt32(header.correlation_type)) << 16) + header.class_id) << 4) + header.reserved
end

function Base.show(io::IO, c::CorrelationId; debug::Bool=false)
    if debug
        header = CorrelationIdHeader(c)
        println(io, "CorrelationId")
        println(io, "  size $(header.struct_size)")
        println(io, "  value type $(header.correlation_type)")
        println(io, "  class id $(header.class_id)")
        println(io, "  reserved bytes $(header.reserved)")
        print(io, "  value $(c.value)")
    else
        print(io, "CorrelationId($(c.value.ptr))")
    end
end

const DEFAULT_CLASS_ID = UInt32(0)

function CorrelationId(value::UInt64; class_id::UInt32=DEFAULT_CLASS_ID)
    header = CorrelationIdHeader(UInt32(sizeof(CorrelationId)), BLPAPI_CORRELATION_TYPE_INT, class_id, UInt32(0))
    return CorrelationId(header, value)
end

CorrelationId(value::Integer; class_id::UInt32=DEFAULT_CLASS_ID) = CorrelationId(UInt64(value), class_id=class_id)
CorrelationId(header::CorrelationIdHeader, value::UInt64) = CorrelationId(encode_header(header), encode_value(value))
