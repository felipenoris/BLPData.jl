
const GITHUB_REPO_ISSUES_URL = "https://github.com/felipenoris/BLPData.jl/issues"

Base.showerror(io::IO, err::BLPResultErrException{SecurityErr}) = print(io, err.err.security, " error: ", err.err.message)
Base.showerror(io::IO, err::BLPUnknownException) = print(io, "$(err.cause). Please, send a bug report to $GITHUB_REPO_ISSUES_URL with the full log of this error.")
Base.showerror(io::IO, err::BLPTimeoutException) = print(io, "Timeout: exceeded timeout limit of $(err.timeout_milliseconds) milliseconds.")

function BLPUnknownException(cause::AbstractString)
    BLPException(BLPUnknownErr(String(cause)))
end

function FieldErr(security::AbstractString, element::Element{false, BLPAPI_DATATYPE_SEQUENCE})
    @assert has_name(element, "fieldExceptions")
    error_info = element["errorInfo"]
    return FieldErr(
            String(security),
            Symbol(get_element_value(element["fieldId"])),
            get_element_value(error_info["source"]),
            get_element_value(error_info["code"]),
            get_element_value(error_info["category"]),
            get_element_value(error_info["subcategory"]),
            get_element_value(error_info["message"])
        )
end

get_result(r::NamedTupleResult) = r.result
get_result(r::FieldDataVecResult) = r.field_data_vec
unwrap(::Unwrap, r::BLPResultErr) = throw(BLPResultErrException(r))
unwrap(::Unwrap, r::BLPResultOk) = get_result(r)
unwrap(::NoUnwrap, r::BLPResult) = r

function parse_reference_data_response_into!(
            element::Element{false, BLPAPI_DATATYPE_CHOICE},
            result::Dict{String, Any},
            securities::Vector{T1},
            fields::Vector{T2},
            error_handling::ErrorHandling
        ) where {T1<:AbstractString, T2<:AbstractString}

    if !has_name(element, "ReferenceDataResponse")
        throw(BLPUnknownException("Expected response element with name `ReferenceDataResponse`. Got `$(get_name(element))`."))
    end

    response_element = get_choice(element)

    if has_name(response_element, "responseError")
        throw(BLPResponseException("Got responseError. \n$response_element"))
    end

    if !has_name(response_element, "securityData")
        throw(BLPUnknownException("Expected response_element with name `securityData`. Got `$(get_name(response_element))`."))
    end

    parse_security_data_into!(response_element, result, securities, fields, error_handling)
end

function parse_historical_data_response_into!(
            element::Element{false, BLPAPI_DATATYPE_CHOICE},
            result::Dict{String, Any},
            security::AbstractString,
            fields::Vector{T},
            error_handling::ErrorHandling
        ) where {T<:AbstractString}

    if !has_name(element, "HistoricalDataResponse")
        throw(BLPUnknownException("Expected response element with name `HistoricalDataResponse`. Got `$(get_name(element))`."))
    end

    response_element = get_choice(element)

    if has_name(response_element, "responseError")
        throw(BLPResponseException("Got responseError. \n$response_element"))
    end

    if !has_name(response_element, "securityData")
        throw(BLPUnknownException("Expected response_element with name `securityData`. Got `$(get_name(response_element))`."))
    end

    parse_security_data_into!(response_element, result, String(security), fields, error_handling)
end

function parse_security_data_into!(
            security_data_vec::Element{true, BLPAPI_DATATYPE_SEQUENCE},
            result::Dict{String, Any},
            securities::Vector{T1},
            fields::Vector{T2},
            error_handling::ErrorHandling
        ) where {T1<:AbstractString, T2<:AbstractString}

    for security_data_element in get_element_value(security_data_vec)
        security = get_element_value(security_data_element["security"])

        if !(security ∈ securities)
            throw(BLPUnknownException("Security $security not in the requested securities list $securities."))
        end

        parse_security_data_into!(security_data_element, result, security, fields, error_handling)
    end

    nothing
end

function parse_security_data_into!(
            security_data_element::Element{false, BLPAPI_DATATYPE_SEQUENCE},
            result::Dict{String, Any},
            security::String,
            fields::Vector{T2},
            error_handling::ErrorHandling,
        ) where {T2<:AbstractString}

    @assert Symbol(get_name(security_data_element)) == :securityData
    @assert isa(security_data_element, Element{false, BLPAPI_DATATYPE_SEQUENCE})

    if haskey(result, security)
        throw(BLPUnknownException("Got repeated response for security $security."))
    end

    if haskey(security_data_element, "securityError")
        result[security] = unwrap(error_handling, SecurityErr(security, security_data_element["securityError"]))
    else
        result[security] = parse_field_data(security_data_element["fieldData"], security_data_element["fieldExceptions"], security, fields, error_handling)
    end

    nothing
end

function parse_field_data(field_data::Element{false, BLPAPI_DATATYPE_SEQUENCE}, field_exceptions::Element{true, BLPAPI_DATATYPE_SEQUENCE}, security::String, fields::Vector{T}, error_handling::E) where {T<:AbstractString, E<:ErrorHandling}
    data = parse_field_exceptions(field_exceptions, security, error_handling)

    for child_element in each_child_element(field_data)
        data[Symbol(get_name(child_element))] = get_element_value(child_element)
    end

    return unwrap(error_handling, NamedTupleResult(fields, data))
end

function parse_field_data(field_data_vec::Element{true, BLPAPI_DATATYPE_SEQUENCE}, field_exceptions::Element{true, BLPAPI_DATATYPE_SEQUENCE}, security::String, fields::Vector{T}, error_handling::E) where {T<:AbstractString, E<:ErrorHandling}

    field_exceptions_dict = parse_field_exceptions(field_exceptions, security, error_handling)

    result = Vector()
    data_buffer = Dict{Symbol, Any}()

    for field_data in get_element_value(field_data_vec)
        empty!(data_buffer)

        for child_element in each_child_element(field_data)
            data_buffer[Symbol(get_name(child_element))] = get_element_value(child_element)
        end

        push!(result, unwrap(error_handling, NamedTupleResult(fields, data_buffer)))
    end

    return unwrap(error_handling, FieldDataVecResult(field_exceptions_dict, result))
end

function parse_field_exceptions(
            field_exceptions_vec::Element{true, BLPAPI_DATATYPE_SEQUENCE},
            security::AbstractString,
            error_handling::ErrorHandling,
        )

    result = Dict{Symbol, Any}()

    for field_exception in get_element_value(field_exceptions_vec)
        field_sym = Symbol(get_element_value(field_exception["fieldId"]))
        result[field_sym] = unwrap(error_handling, FieldErr(security, field_exception))
    end

    return result
end

function NamedTupleResult(fields::Vector{T}, data::Dict{Symbol, A}) where {T<:AbstractString, A}
    tuple_keys = Symbol.(fields)
    tuple_values = Vector(undef, length(tuple_keys))
    for (i, k) in enumerate(tuple_keys)
        if haskey(data, k)
            tuple_values[i] = data[k]
        else
            tuple_values[i] = missing
        end
    end

    # trick based on the docstring for NamedTuple
    nt = (; zip(tuple_keys, tuple_values)...)
    return NamedTupleResult(nt)
end

function SecurityErr(security::AbstractString, err_element::Element{false, BLPAPI_DATATYPE_SEQUENCE})
    @assert has_name(err_element, "securityError")

    return SecurityErr(
            security,
            get_element_value(err_element["source"]),
            get_element_value(err_element["code"]),
            get_element_value(err_element["category"]),
            get_element_value(err_element["subcategory"]),
            get_element_value(err_element["message"]),
        )
end
