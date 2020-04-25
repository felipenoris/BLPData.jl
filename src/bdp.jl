
"""
    bdp(session::Session, security::AbstractString, fields;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        )

Given a single field name or vector of field names
at the `fields` argument,
return a single named tuple with the result of a
`ReferenceDataRequest` request.

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
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T<:AbstractString}

    queue, corr_id = send_request(session, "//blp/refdata", "ReferenceDataRequest") do req
        push!(req["securities"], security)
        append!(req["fields"], fields)

        if options != nothing
            for (k, v) in options
                req[k] = v
            end
        end
    end

    num_of_elements = 0
    local result

    for_each_response_message_element(queue, corr_id, timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element

        @assert has_name(element, "ReferenceDataResponse")
        response_element = get_choice(element)

        if has_name(response_element, "responseError")
            error("Got responseError. \n$response_element")
        end

        @assert has_name(response_element, "securityData")
        for security_data_element in get_element_value(response_element)

            num_of_elements += 1
            if num_of_elements > 1
                error("bdp should return only one element as response.")
            end

            @assert get_element_value(security_data_element["security"]) == security
            result = to_named_tuple(security_data_element["fieldData"])
        end
    end

    return result
end

function bdp(session::Session, security::AbstractString, fields::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        )

    bdp(session, security, [fields], options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds)
end

function bdp(session::Session, securities::Vector{T1}, fields::Vector{T2};
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T1<:AbstractString, T2<:AbstractString}

    result = Dict()

    @sync for security in securities
        @async result[security] = bdp($session, $security, $fields, options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds)
    end

    return result
end

function bdp(session::Session, securities::Vector{T}, field::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T<:AbstractString}

    bdp(session, securities, [field], options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds)
end
