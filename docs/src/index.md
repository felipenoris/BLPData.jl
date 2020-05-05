
# BLPData.jl

Provides a wrapper for [BLPAPI Library](https://www.bloomberg.com/professional/support/api-library/) to the Julia language.

The BLPAPI is the API Library provided by [Bloomberg L.P.](https://www.bloomberg.com/)
to connect to Bloomberg Professional Services.

This package aims to wrap each BLPAPI "Class" into an equivalent Julia type.
Using this approach, the user can implement any query that BLPAPI provides
and also inspect message schemas to discover what requests and responses are
available from the API, without having to use the C API directly.

## Requirements

* Julia v1.4 or newer.

* Windows, Linux, or macOS.

## Installation

From a Julia session, run:

```julia
julia> using Pkg

julia> Pkg.add("BLPData")
```

## Tutorial

First you need a computer running the [Bloomberg Terminal software](https://www.bloomberg.com/professional/support/software-updates/).
Then you can load the package and create a session.

```julia
julia> using BLPData, Dates, DataFrames

julia> session = BLPData.Session()
Session services available: Set(["//blp/refdata", "//blp/mktdata"])
```

From a running session, use [`BLPData.bdp`](@ref) to get the latest data on a given security or list of securities.

```julia
julia> BLPData.bdp(session, "PETR4 BS Equity", "PX_LAST")
(PX_LAST = 15.95,)

julia> BLPData.bdp(session, "PETR4 BS Equity", ["PX_LAST", "VOLUME"])
(PX_LAST = 15.95, VOLUME = 1.601771e8)

julia> BLPData.bdp(session, ["PETR4 BS Equity", "VALE3 BS Equity"], ["PX_LAST", "VOLUME"])
Dict{Any,Any} with 2 entries:
  "PETR4 BS Equity" => (PX_LAST = 15.95, VOLUME = 1.60177e8)
  "VALE3 BS Equity" => (PX_LAST = 43.76, VOLUME = 5.49037e7)
```

For bulk data, use [`BLPData.bds`](@ref).

```julia
julia> DataFrame( BLPData.bds(session, "PETR4 BS Equity", "COMPANY_ADDRESS") )
4×1 DataFrame
│ Row │ Address                      │
│     │ String                       │
├─────┼──────────────────────────────┤
│ 1   │ Av Republica do Chile 65     │
│ 2   │ Centro                       │
│ 3   │ Rio De Janeiro, RJ 20035-900 │
│ 4   │ Brazil                       │
```

For historical data, use [`BLPData.bdh`](@ref). There is also [`BLPData.bdh_intraday_ticks`](@ref) for intraday ticks.

```julia
julia> DataFrame( BLPData.bdh(session, "PETR4 BS Equity", ["PX_LAST", "VOLUME"], Date(2020, 1, 2), Date(2020, 1, 10) ))
7×3 DataFrame
│ Row │ date       │ PX_LAST │ VOLUME    │
│     │ Date       │ Float64 │ Float64   │
├─────┼────────────┼─────────┼───────────┤
│ 1   │ 2020-01-02 │ 30.7    │ 3.77745e7 │
│ 2   │ 2020-01-03 │ 30.45   │ 7.15956e7 │
│ 3   │ 2020-01-06 │ 30.81   │ 8.1844e7  │
│ 4   │ 2020-01-07 │ 30.69   │ 3.2822e7  │
│ 5   │ 2020-01-08 │ 30.5    │ 4.82156e7 │
│ 6   │ 2020-01-09 │ 30.4    │ 3.61027e7 │
│ 7   │ 2020-01-10 │ 30.27   │ 2.53975e7 │
```

When you're done with a session, you can close it with [`BLPData.stop`](@ref).

```julia
julia> BLPData.stop(session)
```

## Async support

`BLPData.bdh` and `BLPData.bds` also accept a list of tickers. In this case, the result is a `Dict`
where the key is the security name and value is a `Vector` of named tuples.
BLPData will automatically process the securities in parallel.

```julia
julia> BLPData.bdh(session, [ "PETR4 BS Equity", "VALE3 BS Equity" ], ["PX_LAST", "VOLUME"], Date(2020, 1, 2), Date(2020, 1, 10) )
Dict{Any,Any} with 2 entries:
  "PETR4 BS Equity" => Any[(date = 2020-01-02, PX_LAST = 30.7, VOLUME = 3.77745e7), (date = 2020-01-03, PX_LAST = 30.45, VOLUME = 7.15956e7), (date = 2020-01-06, PX_LAST = 30.81, VOLUME = 8.1844e7), (date = 202…

  "VALE3 BS Equity" => Any[(date = 2020-01-02, PX_LAST = 54.33, VOLUME = 1.75097e7), (date = 2020-01-03, PX_LAST = 53.93, VOLUME = 1.72848e7), (date = 2020-01-06, PX_LAST = 53.61, VOLUME = 3.27878e7), (date = 2…
```

In general, public functions that process requests (`BLPData.bdh` and `BLPData.bds` for instance)
support async calls, by making use of the `@async` macro, as shown in the following example.

```julia
function bdh_and_bds_async()
    local bdh_result
    local bds_result

    @sync begin
        @async bdh_result = BLPData.bdh(session, "PETR4 BS Equity", ["PX_LAST", "VOLUME"], Date(2020, 1, 2), Date(2020, 1, 10))
        @async bds_result = BLPData.bds(session, "PETR4 BS Equity", "COMPANY_ADDRESS")
    end

    return bdh_result, bds_result
end

h, s = bdh_and_bds_async()
```

## Subscription

You can subscribe to real-time events using [`BLPData.subscribe`](@ref).

```julia
topic = "//blp/mktdata/ticker/PETR4 BS Equity?fields=BID,ASK"
subscription_list = BLPData.subscribe(session, topic)

i = 1 # event counter
evn = BLPData.try_next_event(session)
while evn != nothing
    println("event \$i")
    println(evn)
    i += 1
    sleep(2) # let's wait for events
    evn = BLPData.try_next_event(session)
end

BLPData.unsubscribe(session, subscription_list)
```

## Service and Operation Schema discovery

A `Session` provides the connection to the BLPAPI.
From a `Session` you can navigate to a `Service`,
which provides access to API data thru an `Operation`.

From an `Operation` you can query for the schema definition
of the operation request.

```julia
session = BLPData.Session()
service = session["//blp/refdata"]
println(BLPData.list_operation_names(service))
operation = service["HistoricalDataRequest"]
println(operation)
```

The `Request` structure is used to send a request related to
some `Operation`. From a `Request` it is possible to create an `Element`,
which is the generic data structure to send and receive data from BLPAPI.
Each `Element` has its own schema.

The following example inspects each step in the request done by [`BLPData.bdh_intraday_ticks`](@ref).

```julia
# create a request
request = BLPData.Request(session, "//blp/refdata", "IntradayTickRequest")
req_element = BLPData.Element(request)

# inspect request's schema
schema = BLPData.SchemaElementDefinition(req_element)
println(schema)

# fill data in the request
req["security"] = "PETR4 BS Equity"
req["startDateTime"] = DateTime(2020, 4, 27, 13)  # from 2020-04-27 13:00
req["endDateTime"] = DateTime(2020, 4, 27, 13, 2) #   to 2020-04-27 13:02
append!(req["eventTypes"], [ "TRADE", "BID", "ASK" ])

# send request
queue, corr_id = BLPData.send_request(req)

# gets the response
response_event = BLPData.try_next_event(queue)

# inspect response schema
itr = BLPData.MessageIterator(response_event)
item, state = iterate(itr)
element = BLPData.Element(item)
schema = BLPData.SchemaElementDefinition(element)
println(schema)

# show response data
println(element)
```

## Getting Help and Contributing

If you're having any trouble, have any questions about this package
or want to ask for a new feature,
just open a new [issue](https://github.com/felipenoris/BLPData.jl/issues).

Contributions are always welcome!

To contribute, fork the project on [GitHub](https://github.com/felipenoris/BLPData.jl)
and send a Pull Request.

## References and Alternative Libraries

* [BLPAPI Library](https://www.bloomberg.com/professional/support/api-library/)

* [Bloomie.jl](https://github.com/ungil/Bloomie.jl)

* [BLPAPI.jl by JuliaComputing](https://juliacomputing.com/products/juliapro#premium-pkgs-1)

* [Rblpapi for R](https://github.com/Rblp/Rblpapi)

## Source Code

The source code for this package is hosted at
[https://github.com/felipenoris/BLPData.jl](https://github.com/felipenoris/BLPData.jl).

## License

The source code for the package **BLPData.jl** is licensed under
the [MIT License](https://raw.githubusercontent.com/felipenoris/BLPData.jl/master/LICENSE).

The **BLPData.jl** package uses and distributes binary files released by Bloomberg Finance L.P.
under the licensing terms included in the file [`LICENSE.blpapi`](https://github.com/felipenoris/BLPData.jl/blob/master/LICENSE.blpapi).

*BLOOMBERG, BLOOMBERG PROFESSIONAL and BLOOMBERG TERMINAL are trademarks and service marks of Bloomberg Finance L.P., a Delaware limited partnership, or its subsidiaries. All rights reserved.*
