
function bdh(session::Session, security::AbstractString, field::AbstractString, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        )

    bdh(session, security, [field], date_start, date_end, periodicity=periodicity, options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds)
end

function bdh(session::Session, securities::Vector{T}, field::AbstractString, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T<:AbstractString}

    bdh(session, securities, [field], date_start, date_end, periodicity=periodicity, options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds)
end

"""
    bdh(session::Session, security::AbstractString, fields, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)

Runs a query for historical data. Returns a `Vector` of named tuples.

Internally, it issues a `HistoricalDataRequest` in `//blp/refdata` service.

See also [`bds`](@ref).

# Arguments

* `fields` argument is either a single string or an array of string values.

* `options` argument expects a key->value pairs or a `Dict`.

* `periodicity` expects the string value for the `periodicitySelection` option.

# Simple query example

```julia
using BLPData, DataFrames, Dates

# opens a session
session = BLPData.Session()

# query historical data
result = BLPData.bdh(session, "IBM US Equity", ["PX_LAST", "VWAP_VOLUME"], Date(2020, 1, 2), Date(2020, 1, 30))

# format result as a `DataFrame`
df = DataFrame(result)
```

# Query with optional parameters

```julia
ticker = "PETR4 BS Equity"
field = "PX_LAST"
options = Dict(
    "periodicityAdjustment" => "CALENDAR",
    "periodicitySelection" => "DAILY",
    "currency" => "BRL",
    "pricingOption" => "PRICING_OPTION_PRICE",
    "nonTradingDayFillOption" => "ACTIVE_DAYS_ONLY",
    "nonTradingDayFillMethod" => "NIL_VALUE",
    "adjustmentFollowDPDF" => false,
    "adjustmentNormal" => true,
    "adjustmentAbnormal" => true,
    "adjustmentSplit" => true
)

# query for adjusted stock price
df = DataFrame(BLPData.bdh(session, ticker, field, Date(2019, 1, 1), Date(2019, 2, 10), options=options))
```
"""
function bdh(session::Session, security::AbstractString, fields::Vector{T}, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        ) where {T<:AbstractString}

    @assert !isempty(fields) "Fields vector should not be empty."

    queue, corr_id = send_request(session, "//blp/refdata", "HistoricalDataRequest") do req
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

    for_each_response_message_element(queue, corr_id, timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element

        if !has_name(element, "HistoricalDataResponse")
            throw(BLPUnknownException("Expected response element with name HistoricalDataResponse. Got $(get_name(element))."))
        end

        response_element = get_choice(element)

        if has_name(response_element, "responseError")
            throw(BLPResponseException("Got responseError. \n$response_element"))
        end

        if !has_name(response_element, "securityData")
            throw(BLPUnknownException("Expected response_element with name `securityData`. Got `$(get_name(response_element))`."))
        end

        @assert get_element_value(response_element["security"]) == security
        field_data_element_array = response_element["fieldData"]
        @assert isa(field_data_element_array, Element{true, BLPAPI_DATATYPE_SEQUENCE})
        push_named_tuples!(result, field_data_element_array)
    end

    #return unwrap(error_handling, result)
    return result
end

"""
    bdh(session::Session, securities::Vector{T1}, fields::Vector{T2}, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T1<:AbstractString, T2<:AbstractString}

Runs a query for historical data.
Returns a `Dict` where the key is the security name and value is a `Vector` of named tuples.

Internally, BLPData will process a `ReferenceDataRequest` request for each security in parallel.
"""
function bdh(session::Session, securities::Vector{T1}, fields::Vector{T2}, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0)
        ) where {T1<:AbstractString, T2<:AbstractString}

    result = Dict()

    @sync for security in securities
        @async result[security] = bdh($session, $security, $fields, $date_start, $date_end, periodicity=$periodicity, options=$options, verbose=$verbose, timeout_milliseconds=$timeout_milliseconds)
    end

    return result
end
