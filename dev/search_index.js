var documenterSearchIndex = {"docs":
[{"location":"api/#API-Reference-1","page":"API Reference","title":"API Reference","text":"","category":"section"},{"location":"api/#","page":"API Reference","title":"API Reference","text":"BLPData.Session\nBLPData.ClientMode\nBLPData.stop\nBLPData.bdh\nBLPData.bds\nBLPData.bdp\nBLPData.get_version_info","category":"page"},{"location":"api/#BLPData.Session","page":"API Reference","title":"BLPData.Session","text":"Session(services...;\n        host=nothing,\n        port=nothing,\n        client_mode=nothing,\n        service_check_timeout_msecs=nothing\n    )\n\nCreates a new session for Bloomberg API.\n\nSee also stop, ClientMode.\n\nExample\n\n# starts a session with default parameters:\n# * host=127.0.0.1, port=8194\n# * client_mode = BLPAPI_CLIENTMODE_AUTO.\n# * services = BLPData.DEFAULT_SERVICE_NAMES\nsession = Blpapi.Session()\n\n# session with customized parameters\ncustomized_session = Blpapi.Session(\"//blp/refdata\",\n    host=\"my_host\",\n    port=4444,\n    client_mode=Blpapi.BLPAPI_CLIENTMODE_DAPI)\n\n\n\n\n\n","category":"type"},{"location":"api/#BLPData.ClientMode","page":"API Reference","title":"BLPData.ClientMode","text":"Sets how to connect to the Bloomberg API.\n\nBLPAPI_CLIENTMODE_AUTO tries to\n\nconnect to Desktop API, and falls back to Server API.\n\nBLPAPI_CLIENTMODE_DAPI connects to Desktop API.\nBLPAPI_CLIENTMODE_SAPI connects to Server API.\n\nThe default when creating SessionOptions is BLPAPI_CLIENTMODE_AUTO.\n\nSee also Session, get_client_mode.\n\n\n\n\n\n","category":"type"},{"location":"api/#BLPData.stop","page":"API Reference","title":"BLPData.stop","text":"stop(session::Session)\n\nStops a session.\n\nOnce a Session has been stopped it can only be destroyed.\n\n\n\n\n\n","category":"function"},{"location":"api/#BLPData.bdh","page":"API Reference","title":"BLPData.bdh","text":"bdh(session::Session, security::AbstractString, fields, date_start::Date, date_end::Date;\n        periodicity=nothing, # periodicitySelection option\n        options=nothing, # expects key->value pairs or Dict\n        verbose::Bool=false,\n        timeout_milliseconds::Integer=UInt32(0)\n\nRuns a query for historical data. Returns a Vector of named tuples.\n\nInternally, it issues a HistoricalDataRequest in //blp/refdata service.\n\nSee also bds.\n\nArguments\n\nfields is either a single string or an array of string values.\noptions argument expects a key->value pairs or a Dict.\nperiodicity expects the string value for the periodicitySelection option.\n\nSimple query example\n\nusing BLPData, DataFrames, Dates\n\n# opens a session\nsession = BLPData.Session()\n\n# query historical data\nresult = BLPData.bdh(session, \"IBM US Equity\", [\"PX_LAST\", \"VWAP_VOLUME\"], Date(2020, 1, 2), Date(2020, 1, 30))\n\n# format result as a `DataFrame`\ndf = DataFrame(result)\n\nQuery with optional parameters\n\nticker = \"PETR4 BS Equity\"\nfield = \"PX_LAST\"\noptions = Dict(\n    \"periodicityAdjustment\" => \"CALENDAR\",\n    \"periodicitySelection\" => \"DAILY\",\n    \"currency\" => \"BRL\",\n    \"pricingOption\" => \"PRICING_OPTION_PRICE\",\n    \"nonTradingDayFillOption\" => \"ACTIVE_DAYS_ONLY\",\n    \"nonTradingDayFillMethod\" => \"NIL_VALUE\",\n    \"adjustmentFollowDPDF\" => false,\n    \"adjustmentNormal\" => true,\n    \"adjustmentAbnormal\" => true,\n    \"adjustmentSplit\" => true\n)\n\n# query for adjusted stock price\ndf = DataFrame(BLPData.bdh(session, ticker, field, Date(2019, 1, 1), Date(2019, 2, 10), options=options))\n\n\n\n\n\nbdh(session::Session, securities::Vector{T1}, fields::Vector{T2}, date_start::Date, date_end::Date;\n        periodicity=nothing, # periodicitySelection option\n        options=nothing, # expects key->value pairs or Dict\n        verbose::Bool=false,\n        timeout_milliseconds::Integer=UInt32(0)\n    ) where {T1<:AbstractString, T2<:AbstractString}\n\nRuns a query for historical data. Returns a Dict where the key is the security name and value is a Vector of named tuples.\n\nInternally, BLPData will process a ReferenceDataRequest request for each security in parallel.\n\n\n\n\n\n","category":"function"},{"location":"api/#BLPData.bds","page":"API Reference","title":"BLPData.bds","text":"bds(session::Session, security::AbstractString, field::AbstractString;\n        options=nothing, # expects key->value pairs or Dict\n        verbose::Bool=false,\n        timeout_milliseconds::Integer=UInt32(0)\n\nRuns a query for reference data of a security. Returns a Vector of named tuples.\n\nInternally, it issues a ReferenceDataRequest in //blp/refdata service.\n\nSee also bdh.\n\nExample\n\nusing BLPData, DataFrames\nsession = BLPData.Session()\nresult = BLPData.bds(session, \"PETR4 BS Equity\", \"COMPANY_ADDRESS\")\ndf = DataFrame(result)\n\n\n\n\n\nbds(session::Session, securities::Vector{T}, field::AbstractString;\n        options=nothing, # expects key->value pairs or Dict\n        verbose::Bool=false,\n        timeout_milliseconds::Integer=UInt32(0)\n    ) where {T<:AbstractString}\n\nRuns a query for reference data of a security. Returns a Dict where the key is the security name and value is a Vector of named tuples.\n\nInternally, BLPData will process a ReferenceDataRequest request for each security in parallel.\n\n\n\n\n\n","category":"function"},{"location":"api/#BLPData.bdp","page":"API Reference","title":"BLPData.bdp","text":"bdp(session::Session, security::AbstractString, fields;\n        options=nothing, # expects key->value pairs or Dict\n        verbose::Bool=false,\n        timeout_milliseconds::Integer=UInt32(0)\n    )\n\nGiven a single field name or vector of field names at the fields argument, return a single named tuple with the result of a ReferenceDataRequest request.\n\nFor bulk data, bds method should be used instead.\n\nExample\n\njulia> BLPData.bdp(session, \"PETR4 BS Equity\", \"PX_LAST\")\n(PX_LAST = 15.95,)\n\njulia> BLPData.bdp(session, \"PETR4 BS Equity\", [\"PX_LAST\", \"VOLUME\"])\n(PX_LAST = 15.95, VOLUME = 1.601771e8)\n\n\n\n\n\n","category":"function"},{"location":"api/#BLPData.get_version_info","page":"API Reference","title":"BLPData.get_version_info","text":"get_version_info() :: VersionInfo\n\nReturns the version of the shared library for Bloomberg API.\n\n\n\n\n\n","category":"function"},{"location":"#BLPData.jl-1","page":"Home","title":"BLPData.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Provides a wrapper for BLPAPI Library to the Julia language.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"The BLPAPI is the API Library provided by Bloomberg L.P. to connect to Bloomberg Professional Services.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"This package aims to wrap each BLPAPI \"Class\" into an equivalent Julia type. Using this approach, the user can implement any query that BLPAPI provides and also inspect message schemas to discover what requests and responses are available from the API.","category":"page"},{"location":"#Requirements-1","page":"Home","title":"Requirements","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Julia v1.4 or newer.\nWindows, Linux or macOS.","category":"page"},{"location":"#Installation-1","page":"Home","title":"Installation","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"From a Julia session, run:","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> using Pkg\n\njulia> Pkg.add(\"BLPData\")","category":"page"},{"location":"#Getting-Help-1","page":"Home","title":"Getting Help","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"If you're having any trouble, have any questions about this package or want to ask for a new feature, just open a new issue.","category":"page"},{"location":"#Tutorial-1","page":"Home","title":"Tutorial","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"First you need a computer running the Bloomberg Terminal software. Then you can load the package and create a session.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> using BLPData, Dates, DataFrames\n\njulia> session = BLPData.Session()\nSession services available: Set([\"//blp/refdata\", \"//blp/mktdata\"])","category":"page"},{"location":"#","page":"Home","title":"Home","text":"From a running session, use BLPData.bdp to get the lastest data on a given security or list of securities.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> BLPData.bdp(session, \"PETR4 BS Equity\", \"PX_LAST\")\n(PX_LAST = 15.95,)\n\njulia> BLPData.bdp(session, \"PETR4 BS Equity\", [\"PX_LAST\", \"VOLUME\"])\n(PX_LAST = 15.95, VOLUME = 1.601771e8)\n\njulia> BLPData.bdp(session, [\"PETR4 BS Equity\", \"VALE3 BS Equity\"], [\"PX_LAST\", \"VOLUME\"])\nDict{Any,Any} with 2 entries:\n  \"PETR4 BS Equity\" => (PX_LAST = 15.95, VOLUME = 1.60177e8)\n  \"VALE3 BS Equity\" => (PX_LAST = 43.76, VOLUME = 5.49037e7)","category":"page"},{"location":"#","page":"Home","title":"Home","text":"For bulk data, use BLPData.bds.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> DataFrame( BLPData.bds(session, \"PETR4 BS Equity\", \"COMPANY_ADDRESS\") )\n4×1 DataFrame\n│ Row │ Address                      │\n│     │ String                       │\n├─────┼──────────────────────────────┤\n│ 1   │ Av Republica do Chile 65     │\n│ 2   │ Centro                       │\n│ 3   │ Rio De Janeiro, RJ 20035-900 │\n│ 4   │ Brazil                       │","category":"page"},{"location":"#","page":"Home","title":"Home","text":"For historical data, use BLPData.bdh.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> DataFrame( BLPData.bdh(session, \"PETR4 BS Equity\", [\"PX_LAST\", \"VOLUME\"], Date(2020, 1, 2), Date(2020, 1, 10) ))\n7×3 DataFrame\n│ Row │ date       │ PX_LAST │ VOLUME    │\n│     │ Date       │ Float64 │ Float64   │\n├─────┼────────────┼─────────┼───────────┤\n│ 1   │ 2020-01-02 │ 30.7    │ 3.77745e7 │\n│ 2   │ 2020-01-03 │ 30.45   │ 7.15956e7 │\n│ 3   │ 2020-01-06 │ 30.81   │ 8.1844e7  │\n│ 4   │ 2020-01-07 │ 30.69   │ 3.2822e7  │\n│ 5   │ 2020-01-08 │ 30.5    │ 4.82156e7 │\n│ 6   │ 2020-01-09 │ 30.4    │ 3.61027e7 │\n│ 7   │ 2020-01-10 │ 30.27   │ 2.53975e7 │","category":"page"},{"location":"#","page":"Home","title":"Home","text":"When you're done with a session, you can close it with BLPData.stop.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> BLPData.stop(session)","category":"page"},{"location":"#Async-support-1","page":"Home","title":"Async support","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"BLPData.bdh and BLPData.bds also accepts a list of tickers. In this case, the result is a Dict where the key is the security name and value is a Vector of named tuples. BLPData will automatically process the securities in parallel.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"julia> BLPData.bdh(session, [ \"PETR4 BS Equity\", \"VALE3 BS Equity\" ], [\"PX_LAST\", \"VOLUME\"], Date(2020, 1, 2), Date(2020, 1, 10) )\nDict{Any,Any} with 2 entries:\n  \"PETR4 BS Equity\" => Any[(date = 2020-01-02, PX_LAST = 30.7, VOLUME = 3.77745e7), (date = 2020-01-03, PX_LAST = 30.45, VOLUME = 7.15956e7), (date = 2020-01-06, PX_LAST = 30.81, VOLUME = 8.1844e7), (date = 202…\n\n  \"VALE3 BS Equity\" => Any[(date = 2020-01-02, PX_LAST = 54.33, VOLUME = 1.75097e7), (date = 2020-01-03, PX_LAST = 53.93, VOLUME = 1.72848e7), (date = 2020-01-06, PX_LAST = 53.61, VOLUME = 3.27878e7), (date = 2…","category":"page"},{"location":"#","page":"Home","title":"Home","text":"In general, public functions that process requests (BLPData.bdh and BLPData.bds for instance) support async calls, by making use of the @async macro, as shown in the following example.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"function bdh_and_bds_async()\n    local bdh_result\n    local bds_result\n\n    @sync begin\n        @async bdh_result = BLPData.bdh(session, \"PETR4 BS Equity\", [\"PX_LAST\", \"VOLUME\"], Date(2020, 1, 2), Date(2020, 1, 10))\n        @async bds_result = BLPData.bds(session, \"PETR4 BS Equity\", \"COMPANY_ADDRESS\")\n    end\n\n    return bdh_result, bds_result\nend\n\nh, s = bdh_and_bds_async()","category":"page"},{"location":"#Contributing-1","page":"Home","title":"Contributing","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Contributions are always welcome!","category":"page"},{"location":"#","page":"Home","title":"Home","text":"To contribute, fork the project on GitHub and send a Pull Request.","category":"page"},{"location":"#Alternative-Libraries-1","page":"Home","title":"Alternative Libraries","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"Bloomie.jl\nBLPAPI.jl by JuliaComputing","category":"page"},{"location":"#References-1","page":"Home","title":"References","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"BLPAPI Library\nRblpapi for R","category":"page"},{"location":"#Source-Code-1","page":"Home","title":"Source Code","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"The source code for this package is hosted at https://github.com/felipenoris/BLPData.jl.","category":"page"},{"location":"#License-1","page":"Home","title":"License","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"The source code for the package BLPData.jl is licensed under the MIT License.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"The BLPData.jl package uses and distributes binary files released by Bloomberg Finance L.P. under the licensing terms included in the file LICENSE.blpapi.","category":"page"},{"location":"#","page":"Home","title":"Home","text":"BLOOMBERG, BLOOMBERG PROFESSIONAL and BLOOMBERG TERMINAL are trademarks and service marks of Bloomberg Finance L.P., a Delaware limited partnership, or its subsidiaries. All rights reserved.","category":"page"}]
}