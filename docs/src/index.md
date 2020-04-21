
# BLPData.jl

Provides a wrapper for [BLPAPI Library](https://www.bloomberg.com/professional/support/api-library/) to the Julia language.

The BLPAPI is the API Library provided by [Bloomberg L.P.](https://www.bloomberg.com/)
to connect to Bloomberg Professional Services.

This package aims to wrap each BLPAPI "Class" into an equivalent Julia type.
Using this approach, the user can implement any query that BLPAPI provides
and also inspect message schemas to discover what requests and responses are
available from the API.

## Requirements

* Julia v1.0

* Windows or Linux.

## Installation

From a Julia session, run:

```julia
julia> using Pkg

julia> Pkg.add("BLPData")
```

## Source Code

The source code for this package is hosted at
[https://github.com/felipenoris/BLPData.jl](https://github.com/felipenoris/BLPData.jl).

## License

The source code for the package **BLPData.jl** is licensed under
the [MIT License](https://raw.githubusercontent.com/felipenoris/BLPData.jl/master/LICENSE).

## Getting Help

If you're having any trouble, have any questions about this package
or want to ask for a new feature,
just open a new [issue](https://github.com/felipenoris/BLPData.jl/issues).

## Contributing

Contributions are always welcome!

To contribute, fork the project on [GitHub](https://github.com/felipenoris/BLPData.jl)
and send a Pull Request.

## Development Notice

This package is at an early stage with active development.

Expect *breaking changes* without notice until it reaches version `v0.1`.

## Alternative Libraries

* [Bloomie.jl](https://github.com/ungil/Bloomie.jl)

* [BLPAPI.jl by JuliaComputing](https://juliacomputing.com/products/juliapro#premium-pkgs-1)

## References

* [BLPAPI Library](https://www.bloomberg.com/professional/support/api-library/)

* [Rblpapi for R](https://github.com/Rblp/Rblpapi)

## Notice

*BLOOMBERG and BLOOMBERG PROFESSIONAL are trademarks and service marks of Bloomberg Finance L.P., a Delaware limited partnership, or its subsidiaries. All rights reserved.*
