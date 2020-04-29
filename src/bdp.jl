
"""
    bdp(session::Session, security::AbstractString, fields;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        )

Given a single field name or vector of field names
at the `fields` argument,
return a single named tuple with the result of a
`ReferenceDataRequest` request.

See [`ErrorHandling`](@ref) for `error_handling` argument behavior.

For bulk data, `bds` method should be used instead.

# Example

```julia
julia> BLPData.bdp(session, "PETR4 BS Equity", "PX_LAST")
(PX_LAST = 15.95,)

julia> BLPData.bdp(session, "PETR4 BS Equity", ["PX_LAST", "VOLUME"])
(PX_LAST = 15.95, VOLUME = 1.601771e8)
```
"""
function bdp(session::Session, security::AbstractString, fields::Vector{T};
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        ) where {T<:AbstractString}

    bdp_result = bdp(session, [security], fields, options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds, error_handling=error_handling)
    return bdp_result[security]
end

function bdp(session::Session, security::AbstractString, fields::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        )

    bdp(session, security, [fields], options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds, error_handling=error_handling)
end

function bdp(session::Session, securities::Vector{T1}, fields::Vector{T2};
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        ) where {T1<:AbstractString, T2<:AbstractString}

    @assert !isempty(fields) "Fields vector should not be empty."

    queue, corr_id = send_request(session, "//blp/refdata", "ReferenceDataRequest") do req
        append!(req["securities"], securities)
        append!(req["fields"], fields)

        if options != nothing
            for (k, v) in options
                req[k] = v
            end
        end
    end

    local result::Dict{String, Any} = Dict()

    for_each_response_message_element(queue, corr_id, timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element
        parse_reference_data_response_into!(element, result, securities, fields, error_handling)
    end

    if length(result) != length(securities)
        throw(BLPUnknownException("Expected to return information about $(length(securities)) securities. Got $(length(result))."))
    end

    return result
end

function bdp(session::Session, securities::Vector{T}, field::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        ) where {T<:AbstractString}

    bdp(session, securities, [field], options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds, error_handling=error_handling)
end
