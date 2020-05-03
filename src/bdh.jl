
function bdh(session::Session, security::AbstractString, field::AbstractString, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        )

    bdh(session, security, [field], date_start, date_end, periodicity=periodicity, options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds, error_handling=error_handling)
end

function bdh(session::Session, securities::Vector{T}, field::AbstractString, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        ) where {T<:AbstractString}

    bdh(session, securities, [field], date_start, date_end, periodicity=periodicity, options=options, verbose=verbose, timeout_milliseconds=timeout_milliseconds, error_handling=error_handling)
end

"""
    bdh(session::Session, security::AbstractString, fields, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()

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

    fields_with_date = init_fields_with_date(fields)
    local result::Dict{String, Any} = Dict()

    for_each_response_message_element(queue, corr_id, timeout_milliseconds=timeout_milliseconds, verbose=verbose) do element
        parse_historical_data_response_into!(element, result, security, fields_with_date, error_handling)
    end

    return result[security]
end

function init_fields_with_date_into!(fields::Vector, result::Vector)
    @assert length(result) == length(fields) + 1
    result[1] = "date"
    for i in 1:length(fields)
        result[i+1] = fields[i]
    end
    return result
end

function init_fields_with_date(fields::Vector{String}) :: Vector{String}
    result = Vector{String}(undef, length(fields)+1)
    init_fields_with_date_into!(fields, result)
end

function init_fields_with_date(fields::Vector{T}) :: Vector{AbstractString} where {T<:AbstractString}
    result = Vector{AbstractString}(undef, length(fields)+1)
    init_fields_with_date_into!(fields, result)
end

"""
    bdh(session::Session, securities::Vector{T1}, fields::Vector{T2}, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        ) where {T1<:AbstractString, T2<:AbstractString}

Runs a query for historical data.
Returns a `Dict` where the key is the security name and value is a `Vector` of named tuples.

Internally, BLPData will process a `ReferenceDataRequest` request for each security in parallel.
"""
function bdh(session::Session, securities::Vector{T1}, fields::Vector{T2}, date_start::Date, date_end::Date;
            periodicity=nothing, # periodicitySelection option
            options=nothing, # expects key->value pairs or Dict
            verbose::Bool=false,
            timeout_milliseconds::Integer=UInt32(0),
            error_handling::ErrorHandling=Unwrap()
        ) where {T1<:AbstractString, T2<:AbstractString}

    result = Dict()

    @sync for security in securities
        @async result[security] = bdh($session, $security, $fields, $date_start, $date_end, periodicity=$periodicity, options=$options, verbose=$verbose, timeout_milliseconds=$timeout_milliseconds, error_handling=$error_handling)
    end

    return result
end
