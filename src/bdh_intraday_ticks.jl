
const AllowedDateTimeField = Union{BLPDateTime, DateTime, Date}

"""
    bdh_intraday_ticks(session, security, event_types, date_start, date_end;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        )

Runs a `IntradayTickRequest` request.

# Example

```julia
d0 = DateTime(2020, 4, 27, 13)
d1 = DateTime(2020, 4, 27, 13, 5)
res = BLPData.bdh_intraday_ticks(session, "PETR4 BS Equity", ["TRADE", "BID", "ASK"], d0, d1)
df = DataFrame(res)
show(df)
```
"""
function bdh_intraday_ticks(session::Session, security::AbstractString, event_types::Vector{T}, date_start::T1, date_end::T2;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T<:AbstractString, T1<:AllowedDateTimeField, T2<:AllowedDateTimeField}

    @assert !isempty(event_types) "Event types vector is empty."

    queue, corr_id = send_request(session, "//blp/refdata", "IntradayTickRequest") do req
        req["security"] = security
        req["startDateTime"] = date_start
        req["endDateTime"] = date_end
        append!(req["eventTypes"], event_types)

        if options != nothing
            for (k, v) in options
                req[k] = v
            end
        end
    end

    result = Vector()

    for_each_response_message_element(queue, corr_id, timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element
        @assert has_name(element, "IntradayTickResponse")
        response_element = get_choice(element)

        if has_name(response_element, "responseError")
            error("Got responseError. \n$response_element")
        end

        @assert has_name(response_element, "tickData")
        tick_data_array = response_element["tickData"]
        @assert isa(tick_data_array, Element{true, BLPAPI_DATATYPE_SEQUENCE})
        push_named_tuples!(result, tick_data_array)
    end

    return result
end

function bdh_intraday_ticks(session::Session, securities::Vector{T1}, event_types::Vector{T2}, date_start::DT1, date_end::DT2;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T1<:AbstractString, T2<:AbstractString, DT1<:AllowedDateTimeField, DT2<:AllowedDateTimeField}

    result = Dict()

    @sync for security in securities
        @async result[security] = bdh_intraday_ticks($session, $security, $event_types, $date_start, $date_end, options=$options, verbose=$verbose, timeout_milliseconds=$timeout_milliseconds)
    end

    return result
end

function bdh_intraday_ticks(session::Session, security::AbstractString, event_type::AbstractString, date_start::T1, date_end::T2;
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T1<:AllowedDateTimeField, T2<:AllowedDateTimeField}

    bdh_intraday_ticks(session, security, [event_type], date_start, date_end, options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds)
end
