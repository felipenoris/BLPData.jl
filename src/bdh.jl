
function bdh(session::Session, security::AbstractString, field::AbstractString, date_start::Date, date_end::Date;
            periodicity=nothing,
            options=nothing
        )
    bdh(session, security, [field], date_start, date_end, periodicity=periodicity, options=options)
end

function bdh(session::Session, security::AbstractString, fields::Vector{T}, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false
        ) where {T<:AbstractString}

    @assert !isempty(fields) "Fields vector is empty."

    service = Service(session, "//blp/refdata")
    req = Request(service, "HistoricalDataRequest")
    elements = Element(req)

    # inspect result schema
    # elements_schema = BLP.SchemaElementDefinition(elements)

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

    corr_id = send_request(req)

    tuple_keys = Tuple(append!([:date], [ Symbol(f) for f in fields ]))
    result = Vector()
    row_data = Vector() # buffer

    while true
        response_event = next_event(session)

        if response_event.event_type == BLPAPI_EVENTTYPE_TIMEOUT
            error("Response Timeout.")

        elseif response_event.event_type != BLPAPI_EVENTTYPE_RESPONSE && response_event.event_type != BLPAPI_EVENTTYPE_PARTIAL_RESPONSE
            verbose && @warn("Ignoring response event $(response_event.event_type)")
            continue
        end

        # process BLPAPI_EVENTTYPE_RESPONSE or BLPAPI_EVENTTYPE_PARTIAL_RESPONSE
        for message in each_message(response_event)
            if corr_id ∈ message.correlation_ids
                element = Element(message)
                @assert has_name(element, "HistoricalDataResponse")
                response_element = get_choice(element)

                if has_name(response_element, "responseError")
                    error("Got responseError. \n$response_element")
                end

                @assert has_name(response_element, "securityData")
                @assert get_element_value(response_element["security"]) == security
                field_data_element_array = response_element["fieldData"]
                @assert is_array(field_data_element_array)

                for field_data in get_element_value(field_data_element_array)

                    # reset row_data buffer
                    empty!(row_data)

                    push!(row_data, get_element_value(field_data["date"]))

                    for f in fields
                        if haskey(field_data, f)
                            push!(row_data, get_element_value(field_data[f]))
                        else
                            push!(row_data, missing)
                        end
                    end

                    push!(result, (; zip(tuple_keys, Tuple(row_data))...)) # trick based on the docstring for NamedTuple
                end
            else
                error("Got message with unexpected correlation id: $corr_id: $message.")
            end
        end

        # check if response is complete
        if response_event.event_type == BLPAPI_EVENTTYPE_RESPONSE
            break
        end
    end

    return result
end
