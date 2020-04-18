
function bdh(session::Session, security::AbstractString, field::AbstractString, date_start::Date, date_end::Date;
            periodicity=nothing,
            options=nothing
        )
    bdh(session, security, [field], date_start, date_end, periodicity=periodicity, options=options)
end

function bdh(session::Session, security::AbstractString, fields::Vector{T}, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T<:AbstractString}

    @assert !isempty(fields) "Fields vector is empty."

    corr_id = send_request(session, "//blp/refdata", "HistoricalDataRequest") do req
        push!(req["securities"], security)
        append!(req["fields"], fields)
        req["startDate"] = date_start
        req["endDate"] = date_end

        # optional args
        if periodicity != nothing
            req["periodicitySelection"] = periodicity
        end

        if options != nothing
            for (k, v) in options
                req[k] = v
            end
        end
    end

    result = Vector()
    for_each_response_message_element(session, corr_id, timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element

        @assert has_name(element, "HistoricalDataResponse")
        response_element = get_choice(element)

        if has_name(response_element, "responseError")
            error("Got responseError. \n$response_element")
        end

        @assert has_name(response_element, "securityData")
        @assert get_element_value(response_element["security"]) == security
        field_data_element_array = response_element["fieldData"]
        @assert isa(field_data_element_array, Element{true, BLPAPI_DATATYPE_SEQUENCE})
        push_named_tuples!(result, field_data_element_array)
    end

    return result
end
