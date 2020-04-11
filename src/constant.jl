
function BLPConstant(handle::Ptr{Cvoid})
    ptr_check(handle, "Failed to create BLPConstant")
    name = BLPName(blpapi_Constant_name(handle))
    description = unsafe_string(blpapi_Constant_description(handle))
    status = SchemaStatus(blpapi_Constant_status(handle))
    datatype = BLPDataType(blpapi_Constant_datatype(handle))
    value = parse_blpapi_const_value(handle, datatype)
    return BLPConstant{datatype, typeof(value)}(name, description, status, datatype, value)
end

function BLPConstantList(handle::Ptr{Cvoid})
    ptr_check(handle, "Failed to create BLPConstantList")
    name = BLPName(blpapi_ConstantList_name(handle))
    description = unsafe_string(blpapi_ConstantList_description(handle))
    status = SchemaStatus(blpapi_ConstantList_status(handle))
    datatype = BLPDataType(blpapi_ConstantList_datatype(handle))

    num_constants = blpapi_ConstantList_numConstants(handle)
    if num_constants == 0
        list = Vector{BLPConstant}()
    else
        @assert num_constants > 0
        list = [ BLPConstant(blpapi_ConstantList_getConstantAt(handle, i)) for i in 0:(num_constants-1) ]
    end

    return BLPConstantList{datatype}(name, description, status, datatype, list)
end

function parse_blpapi_const_value(handle::Ptr{Cvoid}, datatype::BLPDataType)

    _error_check(code) = error_check(code, "Error parsing $datatype")

    if datatype == BLPAPI_DATATYPE_CHAR
        buffer = Ref{Cchar}()
        err = blpapi_Constant_getValueAsChar(handle, buffer)
        _error_check(err)
        return Char(buffer[])

    elseif datatype == BLPAPI_DATATYPE_INT32
        buffer = Ref{Int32}()
        err = blpapi_Constant_getValueAsInt32(handle, buffer)
        _error_check(err)
        return buffer[]

    elseif datatype == BLPAPI_DATATYPE_INT64
        buffer = Ref{Int64}()
        err = blpapi_Constant_getValueAsInt64(handle, buffer)
        _error_check(err)
        return buffer[]

    elseif datatype == BLPAPI_DATATYPE_FLOAT32
        buffer = Ref{Float32}()
        err = blpapi_Constant_getValueAsFloat32(handle, buffer)
        _error_check(err)
        return buffer[]

    elseif datatype == BLPAPI_DATATYPE_FLOAT64
        buffer = Ref{Float64}()
        err = blpapi_Constant_getValueAsFloat64(handle, buffer)
        _error_check(err)
        return buffer[]

    elseif datatype == BLPAPI_DATATYPE_DATETIME
        buffer = Ref{BLPDateTime}()
        err = blpapi_Constant_getValueAsDatetime(handle, buffer)
        _error_check(err)
        return buffer[]

    elseif datatype == BLPAPI_DATATYPE_STRING
        buffer = Ref{Cstring}()
        err = blpapi_Constant_getValueAsString(handle, buffer)
        return unsafe_string(buffer[])
    end

    error("Unsupported datatype $datatype.")
end
