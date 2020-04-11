
"""
Sets how to connect to the Bloomberg API.

* `BLPAPI_CLIENTMODE_AUTO` tries to
connect to Desktop API, and falls back to Server API.

* `BLPAPI_CLIENTMODE_DAPI` connects to Desktop API.

* `BLPAPI_CLIENTMODE_SAPI` connects to Server API.

The default when creating `SessionOptions`
is `BLPAPI_CLIENTMODE_AUTO`.

See also [`Session`](@ref), [`get_client_mode`](@ref).
"""
@enum ClientMode::Cint begin
    BLPAPI_CLIENTMODE_AUTO        =  0
    BLPAPI_CLIENTMODE_DAPI        =  1
    BLPAPI_CLIENTMODE_SAPI        =  2
    BLPAPI_CLIENTMODE_COMPAT_33X  =  16
end

# as defined in blpapi_types.h
@enum BLPDataType::Cint begin
    BLPAPI_DATATYPE_BOOL           = 1  # Bool
    BLPAPI_DATATYPE_CHAR           = 2  # Char
    BLPAPI_DATATYPE_BYTE           = 3  # Unsigned 8 bit value
    BLPAPI_DATATYPE_INT32          = 4  # 32 bit Integer
    BLPAPI_DATATYPE_INT64          = 5  # 64 bit Integer
    BLPAPI_DATATYPE_FLOAT32        = 6  # 32 bit Floating point - IEEE
    BLPAPI_DATATYPE_FLOAT64        = 7  # 64 bit Floating point - IEEE
    BLPAPI_DATATYPE_STRING         = 8  # ASCIIZ string
    BLPAPI_DATATYPE_BYTEARRAY      = 9  # Opaque binary data
    BLPAPI_DATATYPE_DATE           = 10 # Date
    BLPAPI_DATATYPE_TIME           = 11 # Timestamp
    BLPAPI_DATATYPE_DECIMAL        = 12 #
    BLPAPI_DATATYPE_DATETIME       = 13 # Date and time
    BLPAPI_DATATYPE_ENUMERATION    = 14 # An opaque enumeration
    BLPAPI_DATATYPE_SEQUENCE       = 15 # Sequence type
    BLPAPI_DATATYPE_CHOICE         = 16 # Choice type
    BLPAPI_DATATYPE_CORRELATION_ID = 17 # Used for some internal
end

@enum SchemaStatus::Cint begin
    BLPAPI_STATUS_ACTIVE               = 0
    BLPAPI_STATUS_DEPRECATED           = 1
    BLPAPI_STATUS_INACTIVE             = 2
    BLPAPI_STATUS_PENDING_DEPRECATION  = 3
end

@enum CorrelationType::Cint begin
    BLPAPI_CORRELATION_TYPE_UNSET   = 0
    BLPAPI_CORRELATION_TYPE_INT     = 1
    BLPAPI_CORRELATION_TYPE_POINTER = 2
    BLPAPI_CORRELATION_TYPE_AUTOGEN = 3
end

"""
Represents the library version in use for Bloomberg API.

See [`get_version_info`](@ref).
"""
struct VersionInfo
    major::Int32
    minor::Int32
    patch::Int32
    build::Int32
end

mutable struct SessionOptions
    handle::Ptr{Cvoid}

    function SessionOptions(handle::Ptr{Cvoid})
        new_session_options = new(handle)
        finalizer(destroy!, new_session_options)
        return new_session_options
    end
end

function destroy!(opt::SessionOptions)
    if opt.handle != C_NULL
        blpapi_SessionOptions_destroy(opt.handle)
        opt.handle = C_NULL
    end
    nothing
end

mutable struct Session
    handle::Ptr{Cvoid}
    opened_services::Set{String}

    function Session(handle::Ptr{Cvoid}, opened_services::Set{String})
        new_session = new(handle, opened_services)
        finalizer(destroy!, new_session)
        return new_session
    end
end

function destroy!(session::Session)
    if session.handle != C_NULL
        blpapi_Session_destroy(session.handle)
        session.handle = C_NULL
    end
    nothing
end

#=
typedef struct blpapi_CorrelationId_t_ {
    unsigned int  size:8;       // fill in the size of this struct
    unsigned int  valueType:4;  // type of value held by this correlation id
    unsigned int  classId:16;   // user defined classification id
    unsigned int  reserved:4;   // for internal use must be 0

    union {
        blpapi_UInt64_t      intValue;
        blpapi_ManagedPtr_t  ptrValue;
    } value;
} blpapi_CorrelationId_t;
=#

#=
mutable struct CorrelationId
#    unsigned int  size:8;       // fill in the size of this struct
#    unsigned int  valueType:4;  // type of value held by this correlation id
#    unsigned int  classId:16;   // user defined classification id
#    unsigned int  reserved:4;   // for internal use must be 0
    size_valueType_classId_reserved::UInt32
    value::UInt64 # union with either UInt64 or Ptr
end
=#

mutable struct CorrelationId
    header::NTuple{8, UInt8}
    value::UInt64
end

mutable struct Service
    handle::Ptr{Cvoid}
    name::String
    session::Session
end

mutable struct BLPName
    handle::Ptr{Cvoid}
    symbol::Symbol

    function BLPName(handle::Ptr{Cvoid})
        ptr_check(handle, "Failed to create BLPName")
        sym = Symbol(unsafe_string(blpapi_Name_string(handle)))
        new_blp_name = new(handle, sym)
        finalizer(destroy!, new_blp_name)
        return new_blp_name
    end
end

function destroy!(name::BLPName)
    if name.handle != C_NULL
        blpapi_Name_destroy(name.handle)
        name.handle = C_NULL
    end
    nothing
end

# D is the value of datatype field
# T is the DataType for the Julia value
struct BLPConstant{D,T}
    name::BLPName
    description::String
    status::SchemaStatus
    datatype::BLPDataType
    value::T
end

struct BLPConstantList{D}
    name::BLPName
    description::String
    status::SchemaStatus
    datatype::BLPDataType
    list::Vector{BLPConstant}
end

"Wraps a blpapi_Datetime_t"
struct BLPDateTime
    parts::UInt8 # bitmask of date/time parts that are set
    hours::UInt8
    minutes::UInt8
    seconds::UInt8
    milliSeconds::UInt16
    month::UInt8
    day::UInt8
    year::UInt16
    offset::Int16 # (signed) minutes ahead of UTC
end

"""
    AbstractSchemaTypeDefinition{T}

Wraps a `blpapi_SchemaTypeDefinition_t` from BLPAPI.

The `T` type parameter is the value of the `datatype` field.

There are three concrete types for an `AbstractSchemaTypeDefinition`:

## Simple

A `SimpleSchemaTypeDefinition` is suitable when `datatype` implies a simple data type.
BLPAPI defines `blpapi_SchemaTypeDefinition_isSimple` to check for simple data type.

See also [`is_simple_datatype`](@ref).

## Complex

A `ComplexSchemaTypeDefinition` is suitable when `datatype` implies a compelx data type,
meaning either a `BLPAPI_DATATYPE_SEQUENCE` or `BLPAPI_DATATYPE_CHOICE`.
BLPAPI defines `blpapi_SchemaTypeDefinition_isComplex` to check for complex data type.

This struct has the same fields as for the Simple case,
with additional `elements::Vector{SchemaElementDefinition}` field.

See also [`is_complex_datatype`](@ref).

## Enumeration

A `EnumerationSchemaTypeDefinition` is suitable when `datatype` equals `BLPAPI_DATATYPE_ENUMERATION`.
BLPAPI defines `blpapi_SchemaTypeDefinition_isEnumeration` to check for enumeration data type.

An enumeration is also considered a simple datatype, so `blpapi_SchemaTypeDefinition_isSimple`
also returns a `true` value for this data type.

See also [`is_enumeration_datatype`](@ref).
"""
abstract type AbstractSchemaTypeDefinition{T} end

abstract type AbstractSchemaElementDefinition end

struct SchemaElementDefinition{T<:AbstractSchemaTypeDefinition} <: AbstractSchemaElementDefinition
    name::BLPName
    status::SchemaStatus
    schema_type::T
    alternate_names::Vector{BLPName}
    min_values::UInt64
    max_values::UInt64
end

"""
    SimpleSchemaTypeDefinition{T}

See docstring for [`AbstractSchemaTypeDefinition`](@ref).
"""
struct SimpleSchemaTypeDefinition{T} <: AbstractSchemaTypeDefinition{T}
    name::BLPName
    description::String
    status::SchemaStatus
    datatype::BLPDataType

    function SimpleSchemaTypeDefinition(name::BLPName, description::String, status::SchemaStatus, datatype::BLPDataType)
        @assert is_simple_datatype(datatype) "$datatype not a simple datatype."
        return new{datatype}(name, description, status, datatype)
    end
end

"""
    ComplexSchemaTypeDefinition{T}

See docstring for [`AbstractSchemaTypeDefinition`](@ref).
"""
struct ComplexSchemaTypeDefinition{T, D<:SchemaElementDefinition} <: AbstractSchemaTypeDefinition{T}
    name::BLPName
    description::String
    status::SchemaStatus
    datatype::BLPDataType
    elements::Vector{D}

    function ComplexSchemaTypeDefinition(name::BLPName, description::String, status::SchemaStatus, datatype::BLPDataType, elements::Vector{D}) where {D<:SchemaElementDefinition}
        @assert is_complex_datatype(datatype) "$datatype is not a complex datatype."
        return new{datatype, D}(name, description, status, datatype, elements)
    end
end

"""
    EnumerationSchemaTypeDefinition{T}

See docstring for [`AbstractSchemaTypeDefinition`](@ref).
"""
struct EnumerationSchemaTypeDefinition{T,L<:BLPConstantList} <: AbstractSchemaTypeDefinition{T}
    name::BLPName
    description::String
    status::SchemaStatus
    datatype::BLPDataType
    enumeration::L

    function EnumerationSchemaTypeDefinition(name::BLPName, description::String, status::SchemaStatus, datatype::BLPDataType, enumeration::L) where {L<:BLPConstantList}
        new{datatype, L}(name, description, status, datatype, enumeration)
    end
end

struct Operation{S<:SchemaElementDefinition}
    name::String
    request_definition::S
    response_definitions::Vector{AbstractSchemaElementDefinition}
end
