
"""
    bds(session::Session, security::AbstractString, field::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)

Runs a query for reference data of a security. Returns a `Vector` of named tuples.

Internally, it issues a `ReferenceDataRequest` in `//blp/refdata` service.

See also [`bdh`](@ref).

# Example

```julia
using BLPData, DataFrames
session = BLPData.Session()
result = BLPData.bds(session, "PETR4 BS Equity", "COMPANY_ADDRESS")
df = DataFrame(result)
```
"""
function bds(session::Session, security::AbstractString, field::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        )

    queue, corr_id = send_request(session, "//blp/refdata", "ReferenceDataRequest") do req
        push!(req["securities"], security)
        push!(req["fields"], field)

        if options != nothing
            for (k, v) in options
                req[k] = v
            end
        end
    end

    result = Vector()

    for_each_response_message_element(queue, corr_id, timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element
        @assert has_name(element, "ReferenceDataResponse")
        response_element = get_choice(element)

        if has_name(response_element, "responseError")
            error("Got responseError. \n$response_element")
        end

        @assert has_name(response_element, "securityData")
        for security_data_element in get_element_value(response_element)
            @assert get_element_value(security_data_element["security"]) == security
            push_named_tuples!(result, security_data_element["fieldData"][field])
        end
    end

    return result
end

"""
    bds(session::Session, securities::Vector{T}, field::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T<:AbstractString}

Runs a query for reference data of a security.
Returns a `Dict` where the key is the security name and value is a `Vector` of named tuples.

Internally, BLPData will process a `ReferenceDataRequest` request for each security in parallel.
"""
function bds(session::Session, securities::Vector{T}, field::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T<:AbstractString}

    result = Dict()

    @sync for security in securities
        @async result[security] = bds($session, $security, $field, options=$options, verbose=$verbose, timeout_milliseconds=$timeout_milliseconds)
    end

    return result
end
