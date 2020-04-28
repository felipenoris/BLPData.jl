
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

* Julia v1.4 or newer.

* Windows, Linux, or macOS.

## Installation

From a Julia session, run:

```julia
julia> using Pkg

julia> Pkg.add("BLPData")
```

## Documentation

Package documentation is hosted at https://felipenoris.github.io/BLPData.jl/stable.

## License

The source code for the package **BLPData.jl** is licensed under
the [MIT License](https://raw.githubusercontent.com/felipenoris/BLPData.jl/master/LICENSE).

The **BLPData.jl** package uses and distributes binary files released by Bloomberg Finance L.P.
under the licensing terms included in the file [`LICENSE.blpapi`](https://github.com/felipenoris/BLPData.jl/blob/master/LICENSE.blpapi).

*BLOOMBERG, BLOOMBERG PROFESSIONAL and BLOOMBERG TERMINAL are trademarks and service marks of Bloomberg Finance L.P., a Delaware limited partnership, or its subsidiaries. All rights reserved.*
