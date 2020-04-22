
# BLPData.jl

[![License][license-img]](LICENSE)
[![appveyor][appveyor-img]][appveyor-url]
[![travis][travis-img]][travis-url]
[![dev][docs-dev-img]][docs-dev-url]
[![stable][docs-stable-img]][docs-stable-url]

[license-img]: http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat-square
[appveyor-img]: https://img.shields.io/appveyor/ci/felipenoris/blpdata-jl/master.svg?logo=appveyor&label=Windows&style=flat-square
[appveyor-url]: https://ci.appveyor.com/project/felipenoris/blpdata-jl/branch/master
[travis-img]: https://img.shields.io/travis/felipenoris/BLPData.jl/master.svg?logo=travis&label=macOS&style=flat-square
[travis-url]: https://travis-ci.org/felipenoris/BLPData.jl
[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg?style=flat-square
[docs-dev-url]: https://felipenoris.github.io/BLPData.jl/dev
[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square
[docs-stable-url]: https://felipenoris.github.io/BLPData.jl/stable

Provides a wrapper for [BLPAPI Library](https://www.bloomberg.com/professional/support/api-library/) to the Julia language.

The BLPAPI is the API Library provided by [Bloomberg L.P.](https://www.bloomberg.com/)
to connect to Bloomberg Professional Services.

This package aims to wrap each BLPAPI "Class" into an equivalent Julia type.
Using this approach, the user can implement any query that BLPAPI provides
and also inspect message schemas to discover what requests and responses are
available from the API.

## Requirements

* Julia v1.3 or newer.

* Windows, Linux or macOS.

## Installation

From a Julia session, run:

```julia
julia> using Pkg

julia> Pkg.add("BLPData")
```

## Documentation

Package documentation is hosted at https://felipenoris.github.io/BLPData.jl/stable.

## Example

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

## Development Notice

This package is at an early stage with active development.

Expect *breaking changes* without notice until it reaches version `v0.1`.

## Alternative Libraries

* [Bloomie.jl](https://github.com/ungil/Bloomie.jl)

* [BLPAPI.jl by JuliaComputing](https://juliacomputing.com/products/juliapro#premium-pkgs-1)

## References

* [BLPAPI Library](https://www.bloomberg.com/professional/support/api-library/)

* [Rblpapi for R](https://github.com/Rblp/Rblpapi)

## License

The source code for the package **BLPData.jl** is licensed under
the [MIT License](https://raw.githubusercontent.com/felipenoris/BLPData.jl/master/LICENSE).

The **BLPData.jl** package uses and distributes binary files released by Bloomberg Finance L.P.
under the licensing terms included in the file [`LICENSE.blpapi`](https://github.com/felipenoris/BLPData.jl/blob/master/LICENSE.blpapi).

*BLOOMBERG and BLOOMBERG PROFESSIONAL are trademarks and service marks of Bloomberg Finance L.P., a Delaware limited partnership, or its subsidiaries. All rights reserved.*
