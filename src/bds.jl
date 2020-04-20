
function bds(session::Session, security::AbstractString, field::AbstractString;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T<:AbstractString}

    corr_id = send_request(session, "//blp/refdata", "ReferenceDataRequest") do req
        push!(req["securities"], security)
        push!(req["fields"], field)

        if options != nothing
            for (k, v) in options
                req[k] = v
            end
        end
    end

    result = Vector()
    for_each_response_message_element(session, corr_id, timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element

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
