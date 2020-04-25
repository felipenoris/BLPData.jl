
# BLPData.jl

Provides a wrapper for [BLPAPI Library](https://www.bloomberg.com/professional/support/api-library/) to the Julia language.

The BLPAPI is the API Library provided by [Bloomberg L.P.](https://www.bloomberg.com/)
to connect to Bloomberg Professional Services.

This package aims to wrap each BLPAPI "Class" into an equivalent Julia type.
Using this approach, the user can implement any query that BLPAPI provides
and also inspect message schemas to discover what requests and responses are
available from the API.

## Requirements

* Julia v1.4 or newer.

* Windows, Linux or macOS.

## Installation

From a Julia session, run:

```julia
julia> using Pkg

julia> Pkg.add("BLPData")
```

## Getting Help

If you're having any trouble, have any questions about this package
or want to ask for a new feature,
just open a new [issue](https://github.com/felipenoris/BLPData.jl/issues).

## Tutorial

```julia
julia> using BLPData, Dates, DataFrames

julia> session = BLPData.Session()
Session services available: Set(["//blp/refdata", "//blp/mktdata"])

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

julia> DataFrame( BLPData.bds(session, "PETR4 BS Equity", "COMPANY_ADDRESS") )
4×1 DataFrame
│ Row │ Address                      │
│     │ String                       │
├─────┼──────────────────────────────┤
│ 1   │ Av Republica do Chile 65     │
│ 2   │ Centro                       │
│ 3   │ Rio De Janeiro, RJ 20035-900 │
│ 4   │ Brazil                       │

julia> BLPData.stop(session)
```

## Async support

`BLPData.bdh` and `BLPData.bds` also accepts a list of tickers. In this case, the result is a `Dict`
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

## Contributing

Contributions are always welcome!

To contribute, fork the project on [GitHub](https://github.com/felipenoris/BLPData.jl)
and send a Pull Request.

## Alternative Libraries

* [Bloomie.jl](https://github.com/ungil/Bloomie.jl)

* [BLPAPI.jl by JuliaComputing](https://juliacomputing.com/products/juliapro#premium-pkgs-1)

## References

* [BLPAPI Library](https://www.bloomberg.com/professional/support/api-library/)

* [Rblpapi for R](https://github.com/Rblp/Rblpapi)

## Source Code

The source code for this package is hosted at
[https://github.com/felipenoris/BLPData.jl](https://github.com/felipenoris/BLPData.jl).

## License

The source code for the package **BLPData.jl** is licensed under
the [MIT License](https://raw.githubusercontent.com/felipenoris/BLPData.jl/master/LICENSE).

The **BLPData.jl** package uses and distributes binary files released by Bloomberg Finance L.P.
under the licensing terms included in the file [`LICENSE.blpapi`](https://github.com/felipenoris/BLPData.jl/blob/master/LICENSE.blpapi).

*BLOOMBERG and BLOOMBERG PROFESSIONAL are trademarks and service marks of Bloomberg Finance L.P., a Delaware limited partnership, or its subsidiaries. All rights reserved.*
